//! Owned-JSON C ABI for the embedded OpenHuman runtime.
//!
//! All calls except `status` and `cancel` may block: invoke them off the Flutter
//! UI isolate. Every returned pointer must be freed exactly once by this library.
//! No function takes custody of an input pointer. The host owns signing.

mod agent;
mod error;
mod rpc;
mod validation;

use error::{BridgeError, BridgeResult};
use serde_json::Value;
use std::{
    ffi::{CStr, CString},
    os::raw::c_char,
};

pub const ABI_VERSION: u32 = 1;
pub const UPSTREAM_COMMIT: &str = "036b13e79e4e555ae249f6245966f384d15f35ba";

fn response(action: impl FnOnce() -> BridgeResult<Value>) -> *mut c_char {
    let value = match std::panic::catch_unwind(std::panic::AssertUnwindSafe(action)) {
        Ok(Ok(value)) => value,
        Ok(Err(error)) => error.json(),
        Err(_) => BridgeError::new(
            "NATIVE_PANIC",
            "The native operation failed. Reset the assistant before retrying.",
        )
        .json(),
    };
    // JSON serialization escapes embedded NUL, so a CString cannot fail here.
    CString::new(value.to_string())
        .expect("JSON never contains a literal NUL")
        .into_raw()
}

/// `ptr` must identify a readable, NUL-terminated C string for the call duration.
unsafe fn argument(ptr: *const c_char, max_bytes: usize) -> BridgeResult<String> {
    if ptr.is_null() {
        return Err(BridgeError::new(
            "INVALID_ARGUMENT",
            "A required argument is missing.",
        ));
    }
    // C ABI callers must provide valid pointers; Rust cannot validate an address.
    let bytes = CStr::from_ptr(ptr).to_bytes();
    if bytes.len() > max_bytes {
        return Err(BridgeError::new(
            "ARGUMENT_TOO_LONG",
            "An argument exceeds its size limit.",
        ));
    }
    let value = std::str::from_utf8(bytes)
        .map_err(|_| BridgeError::new("INVALID_UTF8", "Arguments must contain valid UTF-8."))?;
    Ok(value.to_owned())
}

/// Initialize one agent. `cache_root` is an existing app-private cache directory.
/// The API key is supplied by the host and used by the ephemeral provider route.
///
/// # Safety
/// All arguments must be valid NUL-terminated UTF-8 strings until return.
#[no_mangle]
pub unsafe extern "C" fn arc_openhuman_init(
    endpoint: *const c_char,
    api_key: *const c_char,
    model: *const c_char,
    cache_root: *const c_char,
) -> *mut c_char {
    response(|| {
        let options = validation::InitOptions::new(
            argument(endpoint, 2048)?,
            argument(api_key, 8192)?,
            argument(model, 256)?,
            argument(cache_root, 4096)?,
        )?;
        agent::initialize(options)
    })
}

/// Run a bounded turn. Empty/null session starts a new in-memory conversation;
/// a nonempty ID must match the session returned by the last successful turn.
///
/// # Safety
/// `prompt` and any nonnull `session_id` must be valid C strings until return.
#[no_mangle]
pub unsafe extern "C" fn arc_openhuman_turn(
    prompt: *const c_char,
    session_id: *const c_char,
) -> *mut c_char {
    response(|| {
        let prompt = argument(prompt, 12_000)?;
        let session = if session_id.is_null() {
            String::new()
        } else {
            argument(session_id, 128)?
        };
        validation::turn(&prompt, &session)?;
        agent::turn(prompt, session)
    })
}

/// Reports native build/runtime state without credentials or network access.
#[no_mangle]
pub extern "C" fn arc_openhuman_status() -> *mut c_char {
    response(agent::status)
}

/// Requests cooperative cancellation of an active init/turn. Returns immediately.
#[no_mangle]
pub extern "C" fn arc_openhuman_cancel() -> *mut c_char {
    response(agent::cancel)
}

/// Removes the agent, credential route and retained conversation. Requires idle.
#[no_mangle]
pub extern "C" fn arc_openhuman_reset() -> *mut c_char {
    response(agent::reset)
}

/// Release a response allocated by this library. Null is a no-op.
///
/// # Safety
/// A nonnull pointer must be an unfreed response returned by this library.
#[no_mangle]
pub unsafe extern "C" fn arc_openhuman_string_free(value: *mut c_char) {
    if !value.is_null() {
        drop(CString::from_raw(value));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    unsafe fn take(pointer: *mut c_char) -> Value {
        let result = serde_json::from_slice(CStr::from_ptr(pointer).to_bytes()).unwrap();
        arc_openhuman_string_free(pointer);
        result
    }
    #[test]
    fn status_crosses_the_c_abi_without_provider_credentials() {
        let value = unsafe { take(arc_openhuman_status()) };
        assert_eq!(value["ok"], true);
        assert_eq!(value["abi_version"], 1);
        assert_eq!(value["upstream_commit"], UPSTREAM_COMMIT);
        assert!(value.get("api_key").is_none());
        assert_eq!(
            value["tools"],
            serde_json::json!(["arc_network_status", "arc_balance"])
        );
    }
    #[test]
    fn abi_handles_null_invalid_utf8_and_owned_strings() {
        unsafe {
            let null = std::ptr::null();
            assert_eq!(
                take(arc_openhuman_init(null, null, null, null))["code"],
                "INVALID_ARGUMENT"
            );
            let bad = [0xffu8, 0];
            assert_eq!(
                take(arc_openhuman_turn(bad.as_ptr().cast(), null))["code"],
                "INVALID_UTF8"
            );
            arc_openhuman_string_free(std::ptr::null_mut());
        }
    }
    #[test]
    fn panic_payload_is_not_disclosed() {
        let value = unsafe { take(response(|| panic!("secret payload must not be in JSON"))) };
        assert_eq!(value["code"], "NATIVE_PANIC");
        assert!(!value.to_string().contains("secret payload"));
    }
}
