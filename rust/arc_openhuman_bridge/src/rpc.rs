//! The model can select one of two typed reads, never an RPC URL or method.
use crate::{
    error::{BridgeError, BridgeResult, CANCELLED, RPC_ERROR},
    validation,
};
use async_trait::async_trait;
use num_bigint::BigUint;
use serde::Deserialize;
use serde_json::{json, Value};
use std::{
    sync::{
        atomic::{AtomicU64, Ordering},
        Arc, Mutex,
    },
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tinytools::{PermissionLevel, Tool, ToolPolicy, ToolResult};
use tokio_util::sync::CancellationToken;

pub const ARC_RPC: &str = "https://rpc.testnet.arc.io";
pub const ARC_CHAIN_ID: u64 = 5_042_002;
const RPC_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_RPC_BYTES: usize = 16_384;
pub type Trace = Arc<Mutex<Vec<Value>>>;

#[derive(Clone)]
pub struct ArcRpc {
    client: reqwest::Client,
    // Construction is private. A test-only constructor can point at a mock.
    endpoint: String,
    next_id: Arc<AtomicU64>,
}

enum ReadMethod {
    ChainId,
    BlockNumber,
    Balance { address: String, block: String },
}
impl ReadMethod {
    fn parts(self) -> (&'static str, Value) {
        match self {
            Self::ChainId => ("eth_chainId", json!([])),
            Self::BlockNumber => ("eth_blockNumber", json!([])),
            Self::Balance { address, block } => ("eth_getBalance", json!([address, block])),
        }
    }
}

impl ArcRpc {
    pub fn new() -> BridgeResult<Self> {
        Self::with_endpoint(ARC_RPC.to_owned())
    }
    fn with_endpoint(endpoint: String) -> BridgeResult<Self> {
        Ok(Self {
            client: reqwest::Client::builder()
                .connect_timeout(Duration::from_secs(10))
                .timeout(RPC_TIMEOUT)
                .redirect(reqwest::redirect::Policy::none())
                .no_proxy()
                .build()
                .map_err(|_| RPC_ERROR)?,
            endpoint,
            next_id: Arc::new(AtomicU64::new(1)),
        })
    }

    async fn quantity(&self, method: ReadMethod) -> BridgeResult<(String, BigUint)> {
        let (method, params) = method.parts();
        let id = self.next_id.fetch_add(1, Ordering::Relaxed);
        let mut response = self
            .client
            .post(&self.endpoint)
            .json(&json!({"jsonrpc": "2.0", "id": id, "method": method, "params": params}))
            .send()
            .await
            .map_err(|_| RPC_ERROR)?;
        if !response.status().is_success()
            || response
                .content_length()
                .is_some_and(|n| n > MAX_RPC_BYTES as u64)
        {
            return Err(RPC_ERROR);
        }
        let mut bytes = Vec::with_capacity(1024);
        while let Some(chunk) = response.chunk().await.map_err(|_| RPC_ERROR)? {
            if bytes.len().saturating_add(chunk.len()) > MAX_RPC_BYTES {
                return Err(RPC_ERROR);
            }
            bytes.extend_from_slice(&chunk);
        }
        let value: Value = serde_json::from_slice(&bytes).map_err(|_| RPC_ERROR)?;
        if value.get("jsonrpc").and_then(Value::as_str) != Some("2.0")
            || value.get("id").and_then(Value::as_u64) != Some(id)
            || value.get("error").is_some()
        {
            return Err(RPC_ERROR);
        }
        let hex = value
            .get("result")
            .and_then(Value::as_str)
            .ok_or(RPC_ERROR)?
            .to_owned();
        let number = parse_quantity(&hex)?;
        Ok((hex, number))
    }

    async fn verified_block(&self) -> BridgeResult<(String, BigUint)> {
        let (_, chain) = self.quantity(ReadMethod::ChainId).await?;
        if chain != BigUint::from(ARC_CHAIN_ID) {
            return Err(BridgeError::new(
                "CHAIN_MISMATCH",
                "The RPC did not report Arc Testnet chain 5042002. No balance was queried.",
            ));
        }
        self.quantity(ReadMethod::BlockNumber).await
    }

    async fn network(&self) -> BridgeResult<Value> {
        let (_, block) = self.verified_block().await?;
        Ok(
            json!({"ok": true, "network": "Arc Testnet", "chain_id": ARC_CHAIN_ID,
            "rpc_url": ARC_RPC, "block_number": block.to_str_radix(10),
            "observed_at_unix": now(), "source": "verified_rpc"}),
        )
    }

    async fn balance(&self, address: String) -> BridgeResult<Value> {
        let (block_hex, block) = self.verified_block().await?;
        let (_, amount) = self
            .quantity(ReadMethod::Balance {
                address: address.clone(),
                block: block_hex,
            })
            .await?;
        Ok(
            json!({"ok": true, "network": "Arc Testnet", "chain_id": ARC_CHAIN_ID,
            "rpc_url": ARC_RPC, "address": address, "token": "USDC", "representation": "native",
            "native_decimals": 18, "balance_wei": amount.to_str_radix(10), "balance_usdc": format_native_usdc(&amount),
            "block_number": block.to_str_radix(10), "observed_at_unix": now(), "source": "verified_rpc"}),
        )
    }
}

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |d| d.as_secs())
}

/// JSON-RPC QUANTITY must be canonical unsigned hexadecimal, at most uint256.
fn parse_quantity(value: &str) -> BridgeResult<BigUint> {
    let digits = value.strip_prefix("0x").ok_or(RPC_ERROR)?;
    if digits.is_empty()
        || digits.len() > 64
        || (digits.len() > 1 && digits.starts_with('0'))
        || !digits.bytes().all(|c| c.is_ascii_hexdigit())
    {
        return Err(RPC_ERROR);
    }
    BigUint::parse_bytes(digits.as_bytes(), 16).ok_or(RPC_ERROR)
}

fn format_native_usdc(value: &BigUint) -> String {
    let scale = BigUint::from(10u8).pow(18);
    let integer = value / &scale;
    let fractional = value % scale;
    if fractional == BigUint::from(0u8) {
        return integer.to_str_radix(10);
    }
    let fraction = format!("{:0>18}", fractional.to_str_radix(10));
    format!(
        "{}.{}",
        integer.to_str_radix(10),
        fraction.trim_end_matches('0')
    )
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct NoArgs {}
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct BalanceArgs {
    address: String,
}

#[derive(Clone, Copy)]
enum Kind {
    Network,
    Balance,
}

struct ArcReadTool {
    rpc: ArcRpc,
    kind: Kind,
    cancellation: CancellationToken,
    trace: Trace,
}

impl ArcReadTool {
    async fn run(&self, args: Value) -> BridgeResult<Value> {
        let read = async {
            match self.kind {
                Kind::Network => {
                    serde_json::from_value::<NoArgs>(args).map_err(|_| {
                        BridgeError::new(
                            "INVALID_TOOL_ARGUMENTS",
                            "arc_network_status accepts an empty JSON object only.",
                        )
                    })?;
                    self.rpc.network().await
                }
                Kind::Balance => {
                    let parsed = serde_json::from_value::<BalanceArgs>(args).map_err(|_| {
                        BridgeError::new(
                            "INVALID_TOOL_ARGUMENTS",
                            "arc_balance requires exactly one string field named address.",
                        )
                    })?;
                    self.rpc
                        .balance(validation::address(&parsed.address)?)
                        .await
                }
            }
        };
        tokio::select! {
            biased;
            _ = self.cancellation.cancelled() => Err(CANCELLED),
            value = tokio::time::timeout(RPC_TIMEOUT, read) => value.unwrap_or(Err(BridgeError::new("RPC_TIMEOUT", "The Arc read exceeded 20 seconds. No result has been inferred."))),
        }
    }
}

#[async_trait]
impl Tool for ArcReadTool {
    fn name(&self) -> &str {
        match self.kind {
            Kind::Network => "arc_network_status",
            Kind::Balance => "arc_balance",
        }
    }
    fn description(&self) -> &str {
        match self.kind {
            Kind::Network => "Reads the live Arc Testnet chain ID and latest block through the fixed official RPC. Fails if chain ID is not 5042002.",
            Kind::Balance => "Reads an address's live native USDC balance on Arc Testnet at a specific block. Values use 18 native decimals and exact decimal strings. Does not sign, send or simulate transactions.",
        }
    }
    fn parameters_schema(&self) -> Value {
        match self.kind {
            Kind::Network => {
                json!({"type": "object", "properties": {}, "required": [], "additionalProperties": false})
            }
            Kind::Balance => {
                json!({"type": "object", "properties": {"address": {"type": "string", "pattern": "^0x[0-9a-fA-F]{40}$", "minLength": 42, "maxLength": 42}}, "required": ["address"], "additionalProperties": false})
            }
        }
    }
    async fn execute(&self, args: Value) -> anyhow::Result<ToolResult> {
        let result = self.run(args).await;
        let value = match result {
            Ok(value) => value,
            Err(error) => error.json(),
        };
        if let Ok(mut trace) = self.trace.lock() {
            if trace.len() < 16 {
                trace.push(json!({"tool": self.name(), "result": value}));
            }
        }
        let output = value.to_string();
        Ok(if value["ok"] == true {
            ToolResult::success(output)
        } else {
            ToolResult::error(output)
        })
    }
    fn permission_level(&self) -> PermissionLevel {
        PermissionLevel::ReadOnly
    }
    fn external_effect(&self) -> bool {
        false
    }
    fn max_result_size_chars(&self) -> Option<usize> {
        Some(4096)
    }
    fn policy(&self) -> ToolPolicy {
        let mut policy = ToolPolicy::read_only();
        policy.side_effects.network = true;
        policy.side_effects.external_service = true;
        policy.runtime.timeout_ms = Some(20_000);
        policy.runtime.max_retries = Some(0);
        policy.runtime.max_result_bytes = Some(4096);
        policy
    }
}

pub fn tools(rpc: &ArcRpc, cancellation: CancellationToken, trace: Trace) -> Vec<Box<dyn Tool>> {
    [Kind::Network, Kind::Balance]
        .into_iter()
        .map(|kind| {
            Box::new(ArcReadTool {
                rpc: rpc.clone(),
                kind,
                cancellation: cancellation.clone(),
                trace: trace.clone(),
            }) as Box<dyn Tool>
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{
        io::{Read, Write},
        net::TcpListener,
        thread,
    };

    fn mock(responses: Vec<Value>) -> (ArcRpc, thread::JoinHandle<Vec<Value>>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let endpoint = format!("http://{}", listener.local_addr().unwrap());
        let handle = thread::spawn(move || {
            let mut requests = Vec::new();
            for response in responses {
                let (mut socket, _) = listener.accept().unwrap();
                socket
                    .set_read_timeout(Some(Duration::from_secs(5)))
                    .unwrap();
                let mut bytes = Vec::new();
                let mut chunk = [0u8; 2048];
                let (end, length) = loop {
                    let n = socket.read(&mut chunk).unwrap();
                    assert!(n > 0);
                    bytes.extend_from_slice(&chunk[..n]);
                    if let Some(end) = bytes.windows(4).position(|w| w == b"\r\n\r\n") {
                        let header = std::str::from_utf8(&bytes[..end]).unwrap();
                        let length = header
                            .lines()
                            .find_map(|s| {
                                s.to_ascii_lowercase()
                                    .strip_prefix("content-length:")
                                    .map(|v| v.trim().parse::<usize>().unwrap())
                            })
                            .unwrap();
                        break (end + 4, length);
                    }
                };
                while bytes.len() < end + length {
                    let n = socket.read(&mut chunk).unwrap();
                    assert!(n > 0);
                    bytes.extend_from_slice(&chunk[..n]);
                }
                requests.push(serde_json::from_slice(&bytes[end..end + length]).unwrap());
                let body = response.to_string();
                write!(socket, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}", body.len(), body).unwrap();
            }
            requests
        });
        (ArcRpc::with_endpoint(endpoint).unwrap(), handle)
    }
    fn reply(id: u64, result: &str) -> Value {
        json!({"jsonrpc": "2.0", "id": id, "result": result})
    }

    #[test]
    fn exact_quantities_cover_dust_and_uint256() {
        assert_eq!(format_native_usdc(&parse_quantity("0x0").unwrap()), "0");
        assert_eq!(
            format_native_usdc(&parse_quantity("0x1").unwrap()),
            "0.000000000000000001"
        );
        assert_eq!(format_native_usdc(&BigUint::from(10u8).pow(18)), "1");
        assert_eq!(
            format_native_usdc(&BigUint::from(1_000_000_000_000u64)),
            "0.000001"
        );
        assert_eq!(
            parse_quantity(&format!("0x{}", "f".repeat(64)))
                .unwrap()
                .bits(),
            256
        );
        for bad in ["0x", "0x00", "0x-1", "1", "0xg", "0x+1"] {
            assert!(parse_quantity(bad).is_err());
        }
        assert!(parse_quantity(&format!("0x1{}", "0".repeat(64))).is_err());
    }
    #[tokio::test]
    async fn balance_uses_verified_chain_and_a_block_snapshot() {
        let (rpc, server) = mock(vec![
            reply(1, "0x4cef52"),
            reply(2, "0x123"),
            reply(3, "0x1"),
        ]);
        let value = rpc
            .balance("0x3600000000000000000000000000000000000000".to_owned())
            .await
            .unwrap();
        assert_eq!(value["balance_wei"], "1");
        assert_eq!(value["balance_usdc"], "0.000000000000000001");
        let requests = server.join().unwrap();
        assert_eq!(
            requests
                .iter()
                .map(|v| v["method"].as_str().unwrap())
                .collect::<Vec<_>>(),
            ["eth_chainId", "eth_blockNumber", "eth_getBalance"]
        );
        assert_eq!(requests[2]["params"][1], "0x123");
    }
    #[tokio::test]
    async fn wrong_chain_stops_before_reading_balance() {
        let (rpc, server) = mock(vec![reply(1, "0x1")]);
        assert_eq!(
            rpc.balance("0x3600000000000000000000000000000000000000".to_owned())
                .await
                .unwrap_err()
                .code,
            "CHAIN_MISMATCH"
        );
        assert_eq!(server.join().unwrap().len(), 1);
    }
    #[tokio::test]
    async fn mismatched_id_errors_and_large_bodies_are_rejected() {
        for response in [
            reply(2, "0x4cef52"),
            json!({"jsonrpc": "2.0", "id": 1, "error": {"message": "server-secret"}}),
            reply(1, &"x".repeat(MAX_RPC_BYTES)),
        ] {
            let (rpc, server) = mock(vec![response]);
            let error = rpc.network().await.unwrap_err();
            assert_eq!(error, RPC_ERROR);
            assert!(!error.json().to_string().contains("server-secret"));
            server.join().unwrap();
        }
    }
    #[tokio::test]
    async fn tools_reject_method_url_and_unknown_fields_without_network() {
        let rpc = ArcRpc::new().unwrap();
        let tools = tools(
            &rpc,
            CancellationToken::new(),
            Arc::new(Mutex::new(Vec::new())),
        );
        for tool in &tools {
            let output = tool
                .execute(json!({"url": "https://evil.example", "method": "eth_sendTransaction"}))
                .await
                .unwrap()
                .output();
            assert!(output.contains("INVALID_TOOL_ARGUMENTS"));
            assert_eq!(tool.permission_level(), PermissionLevel::ReadOnly);
            assert!(!tool.external_effect());
            assert!(!tool.policy().side_effects.payment);
        }
    }
}
