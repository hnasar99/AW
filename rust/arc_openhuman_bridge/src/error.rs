use serde_json::{json, Value};

/// Public errors are deliberately static: provider/RPC bodies and credentials
/// must never become a Dart-visible diagnostic or an exception string.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BridgeError {
    pub code: &'static str,
    pub message: &'static str,
}
pub type BridgeResult<T> = Result<T, BridgeError>;
impl BridgeError {
    pub const fn new(code: &'static str, message: &'static str) -> Self {
        Self { code, message }
    }
    pub fn json(self) -> Value {
        json!({"ok": false, "code": self.code, "error": self.message})
    }
}
pub const BUSY: BridgeError = BridgeError::new(
    "BUSY",
    "The assistant is busy. Cancel the active operation and wait before retrying.",
);
pub const CANCELLED: BridgeError =
    BridgeError::new("CANCELLED", "The active operation was cancelled.");
pub const TIMEOUT: BridgeError = BridgeError::new(
    "TIMEOUT",
    "The assistant operation exceeded its time limit.",
);
pub const STATE_ERROR: BridgeError = BridgeError::new(
    "STATE_ERROR",
    "The native runtime is unavailable. Restart the app.",
);
pub const RPC_ERROR: BridgeError = BridgeError::new(
    "RPC_ERROR",
    "Arc RPC could not return a valid response. No balance or network state has been inferred.",
);
