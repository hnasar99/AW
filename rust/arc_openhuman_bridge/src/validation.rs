use crate::error::{BridgeError, BridgeResult};
use std::path::{Component, PathBuf};
use url::{Host, Url};
use zeroize::Zeroizing;

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum Mode {
    #[default]
    ProposalOnly,
    LabTextOnly,
}

impl Mode {
    pub fn name(self) -> &'static str {
        match self {
            Self::ProposalOnly => "proposal-only",
            Self::LabTextOnly => "lab-text-only",
        }
    }
    pub fn inference(self) -> &'static str {
        match self {
            Self::ProposalOnly => "remote",
            Self::LabTextOnly => "lab-endpoint",
        }
    }
    pub fn tools(self) -> &'static [&'static str] {
        match self {
            Self::ProposalOnly => &["arc_network_status", "arc_balance"],
            Self::LabTextOnly => &[],
        }
    }
}

pub struct InitOptions {
    pub mode: Mode,
    pub endpoint: String,
    pub api_key: Zeroizing<String>,
    pub model: String,
    pub cache_root: PathBuf,
}

impl InitOptions {
    pub fn new(
        endpoint: String,
        api_key: String,
        model: String,
        cache_root: String,
    ) -> BridgeResult<Self> {
        let api_key = Zeroizing::new(api_key);
        if api_key.trim().is_empty() || api_key.chars().any(char::is_control) {
            return Err(BridgeError::new(
                "INVALID_API_KEY",
                "A nonempty API key without control characters is required.",
            ));
        }
        let model = model.trim().to_owned();
        if model.is_empty() || model.chars().any(|c| c.is_control() || c.is_whitespace()) {
            return Err(BridgeError::new(
                "INVALID_MODEL",
                "Supply a nonempty provider model identifier without whitespace.",
            ));
        }
        let cache_root = PathBuf::from(cache_root);
        if !cache_root.is_absolute()
            || cache_root
                .components()
                .any(|c| matches!(c, Component::ParentDir))
        {
            return Err(BridgeError::new(
                "INVALID_CACHE",
                "Supply the existing app-private cache directory as an absolute path.",
            ));
        }
        Ok(Self {
            mode: Mode::ProposalOnly,
            endpoint: endpoint_url(&endpoint)?,
            api_key,
            model,
            cache_root,
        })
    }

    pub fn lab(
        endpoint: String,
        api_key: String,
        model: String,
        cache_root: String,
    ) -> BridgeResult<Self> {
        // Validate before URL normalization: a hostname, integer or alternate
        // spelling must not quietly become an authorized loopback address.
        lab_endpoint(&endpoint)?;
        let mut options = Self::new(endpoint, api_key, model, cache_root)?;
        let model = options.model.to_ascii_lowercase();
        if model.starts_with("hint:") || model.contains('@') || model.contains("cloud") {
            return Err(BridgeError::new(
                "INVALID_LAB_MODEL",
                "Use the exact local model ID, without routing hints, @ overrides or cloud tags.",
            ));
        }
        options.mode = Mode::LabTextOnly;
        Ok(options)
    }
}

fn lab_endpoint(value: &str) -> BridgeResult<()> {
    const INVALID: BridgeError = BridgeError::new(
        "INVALID_LAB_ENDPOINT",
        "The text-only lab requires a literal loopback IP and the exact /v1 API root.",
    );
    let value = value.trim();
    endpoint_url(value)?;
    let parsed = Url::parse(value).map_err(|_| INVALID)?;
    let literal = match parsed.host() {
        Some(Host::Ipv4(ip)) if ip.is_loopback() => ip.to_string(),
        Some(Host::Ipv6(ip)) if ip.is_loopback() => format!("[{ip}]"),
        _ => return Err(INVALID),
    };
    let (authority, path) = value
        .split_once("://")
        .ok_or(INVALID)?
        .1
        .split_once('/')
        .ok_or(INVALID)?;
    let expected = match parsed.port() {
        Some(port) => format!("{literal}:{port}"),
        None => literal,
    };
    if authority != expected || path != "v1" || parsed.path() != "/v1" {
        return Err(INVALID);
    }
    Ok(())
}

pub fn lab_request_id(value: &str) -> BridgeResult<()> {
    let suffix = value.strip_prefix("awlab-").unwrap_or("");
    if suffix.len() != 32
        || !suffix
            .bytes()
            .all(|c| c.is_ascii_digit() || (b'a'..=b'f').contains(&c))
    {
        return Err(BridgeError::new(
            "INVALID_REQUEST_ID",
            "Supply awlab- followed by 32 lowercase hexadecimal characters.",
        ));
    }
    Ok(())
}

pub fn endpoint_url(value: &str) -> BridgeResult<String> {
    const INVALID: BridgeError = BridgeError::new("INVALID_ENDPOINT", "Use an HTTPS API root, or HTTP on an exact loopback host, without credentials, query, fragment or /chat/completions.");
    let value = value.trim();
    let authority = value
        .split_once("://")
        .ok_or(INVALID)?
        .1
        .split(['/', '?', '#'])
        .next()
        .ok_or(INVALID)?;
    if authority.contains('@') || value.contains('\\') || value.chars().any(char::is_control) {
        return Err(INVALID);
    }
    let parsed = Url::parse(value).map_err(|_| INVALID)?;
    let loopback = match parsed.host() {
        Some(Host::Ipv4(ip)) => ip.is_loopback(),
        Some(Host::Ipv6(ip)) => ip.is_loopback(),
        Some(Host::Domain(host)) => host.eq_ignore_ascii_case("localhost"),
        None => false,
    };
    if !(parsed.scheme() == "https" || (parsed.scheme() == "http" && loopback))
        || parsed.host().is_none()
        || !parsed.username().is_empty()
        || parsed.password().is_some()
        || parsed.query().is_some()
        || parsed.fragment().is_some()
        || parsed.port() == Some(0)
        || parsed
            .path()
            .trim_end_matches('/')
            .ends_with("/chat/completions")
    {
        return Err(INVALID);
    }
    Ok(parsed.as_str().trim_end_matches('/').to_owned())
}

pub fn address(value: &str) -> BridgeResult<String> {
    if value.len() != 42
        || !value.starts_with("0x")
        || !value.as_bytes()[2..].iter().all(u8::is_ascii_hexdigit)
    {
        return Err(BridgeError::new(
            "INVALID_ADDRESS",
            "An address must contain 0x followed by exactly 40 hexadecimal digits.",
        ));
    }
    Ok(value.to_ascii_lowercase())
}

pub fn turn(prompt: &str, session: &str) -> BridgeResult<()> {
    if prompt.trim().is_empty() {
        return Err(BridgeError::new(
            "EMPTY_PROMPT",
            "Enter a message for the assistant.",
        ));
    }
    if prompt.len() > 12_000 || session.len() > 128 {
        return Err(BridgeError::new(
            "ARGUMENT_TOO_LONG",
            "The message or session identifier exceeds its size limit.",
        ));
    }
    if !session
        .bytes()
        .all(|c| c.is_ascii_alphanumeric() || c == b'_' || c == b'-')
    {
        return Err(BridgeError::new(
            "INVALID_SESSION",
            "The session identifier is invalid.",
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn lab_rejects_remote_routes_and_model_routing_syntax() {
        for endpoint in ["http://127.0.0.1:11434/v1", "http://[::1]:11434/v1"] {
            assert!(InitOptions::lab(
                endpoint.into(),
                "synthetic".into(),
                "local-model:tag".into(),
                "/tmp".into()
            )
            .is_ok());
        }
        for endpoint in [
            "https://api.example.com/v1",
            "http://localhost:11434/v1",
            "http://127.0.0.1:11434/v1/",
            "http://127.0.0.1:11434/x/../v1",
            "http://127.0.0.1:11434/x/%2e%2e/v1",
            "http://127.0.0.1:11434/api",
            "http://2130706433:11434/v1",
            "http://127.1:11434/v1",
            "http://127.0.0.1:11434/v1?key=test",
            "http://127.0.0.1:11434/v1/chat/completions",
        ] {
            assert!(
                InitOptions::lab(
                    endpoint.into(),
                    "synthetic".into(),
                    "local-model:tag".into(),
                    "/tmp".into()
                )
                .is_err(),
                "{endpoint}"
            );
        }
        for model in ["", "hint:fast", "local@0.8", "model:cloud", "model-cloud"] {
            assert!(
                InitOptions::lab(
                    "http://127.0.0.1:11434/v1".into(),
                    "synthetic".into(),
                    model.into(),
                    "/tmp".into()
                )
                .is_err(),
                "{model}"
            );
        }
        assert!(InitOptions::lab(
            "http://127.0.0.1:11434/v1".into(),
            "".into(),
            "local".into(),
            "/tmp".into()
        )
        .is_err());
    }

    #[test]
    fn correlation_id_cannot_inject_instructions_or_log_lines() {
        assert!(lab_request_id("awlab-0123456789abcdef0123456789abcdef").is_ok());
        for value in [
            "",
            "awlab-0123",
            "awlab-0123456789ABCDEF0123456789ABCDEF",
            "awlab-0123456789abcdef0123456789abcdef\n",
        ] {
            assert!(lab_request_id(value).is_err());
        }
    }
    #[test]
    fn endpoint_checks_parsed_authority_not_a_prefix() {
        for url in [
            "https://example.com/v1",
            "http://127.0.0.1:3000/v1",
            "http://127.12.2.1/v1",
            "http://[::1]:8080/v1",
            "http://localhost/v1",
        ] {
            assert!(endpoint_url(url).is_ok(), "{url}");
        }
        for url in [
            "http://127.evil/v1",
            "http://127.0.0.1.evil/v1",
            "http://localhost.evil/v1",
            "http://example.com",
            "ftp://example.com",
            "https://user:secret@example.com/v1",
            "https://@example.com/v1",
            "https://example.com/v1?key=secret",
            "https://example.com/v1#fragment",
            "https://example.com:0/v1",
            "https://example.com/v1/chat/completions",
            "http://[::ffff:127.0.0.1]/v1",
        ] {
            assert!(endpoint_url(url).is_err(), "{url}");
        }
    }
    #[test]
    fn strict_address_and_session_validation() {
        assert!(address("0x3600000000000000000000000000000000000000").is_ok());
        for bad in [
            "0x",
            "0x360000000000000000000000000000000000000g",
            "0X3600000000000000000000000000000000000000",
            "../../etc/passwd",
        ] {
            assert!(address(bad).is_err());
        }
        assert!(turn("question", "agent-123_session").is_ok());
        assert!(turn("question", "../../other-session").is_err());
        assert!(turn("", "").is_err());
    }
}
