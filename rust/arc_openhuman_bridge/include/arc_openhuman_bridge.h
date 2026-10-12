#ifndef ARC_OPENHUMAN_BRIDGE_H
#define ARC_OPENHUMAN_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

/* ABI version 1. All results are owned, NUL-terminated UTF-8 JSON strings.
 * Free every returned pointer exactly once with arc_openhuman_string_free.
 * Input strings remain owned by the caller and valid until the call returns.
 * init/turn/reset must run off the UI thread; status/cancel are short calls.
 * Do not pass arbitrary addresses, reuse a freed result, or free with libc. */
char *arc_openhuman_init(const char *endpoint, const char *api_key,
                        const char *model, const char *cache_root);
char *arc_openhuman_turn(const char *prompt, const char *session_id);
/* Additive lab capabilities; discover supported_modes through status first.
 * The lab runtime has no tools. Its process-wide policy survives reset.
 * request_id: awlab- followed by exactly 32 lowercase hexadecimal characters.
 * The marker is included in the prompt, not in a custom HTTP header. */
char *arc_openhuman_init_lab(const char *endpoint, const char *api_key,
                            const char *model, const char *cache_root);
char *arc_openhuman_turn_lab(const char *prompt, const char *session_id,
                            const char *request_id);
char *arc_openhuman_status(void);
char *arc_openhuman_cancel(void);
char *arc_openhuman_reset(void);
void arc_openhuman_string_free(char *value);

#ifdef __cplusplus
}
#endif
#endif
