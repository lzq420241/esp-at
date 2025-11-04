# mDNS TXT Query Fix Explanation

## Problem
When using the AT+MDNS command to query for TXT records (`AT+MDNS=2,1,<instance>,<service>,<proto>`), the command returns "no results found" even though Wireshark captures the mDNS response packets.

## Root Cause
The issue is in the ESP-IDF mdns component's `_mdns_search_result_add_txt()` function in `mdns.c`.

When a TXT record response is received for a direct TXT query (type=1), the code path at lines 4146-4150 calls `_mdns_search_result_add_txt()` to add the TXT data to the results. However, when this function creates a new result structure (lines 4904-4920), it only populates:
- `txt` - the TXT record data
- `txt_value_len` - lengths of TXT values
- `txt_count` - number of TXT records  
- `esp_netif` - network interface
- `ip_protocol` - IP protocol (IPv4/IPv6)
- `ttl` - time to live

It does NOT populate:
- `instance_name` - the service instance name
- `service_type` - the service type
- `proto` - the protocol (_tcp/_udp)

These fields are required by the AT command formatter to construct a proper response. Without them, the AT command cannot format the output and reports "no results found".

## Solution
The fix modifies `_mdns_search_result_add_txt()` to populate `instance_name`, `service_type`, and `proto` from the search parameters when creating a new result structure. This matches the behavior of `_mdns_search_result_add_srv()` which already does this correctly (see lines 4868-4872).

The patch adds the following code after line 4910 (after `memset(r, 0, sizeof(mdns_result_t));`):

```c
if (search->instance) {
    r->instance_name = mdns_mem_strdup(search->instance);
}
if (search->service) {
    r->service_type = mdns_mem_strdup(search->service);
}
r->proto = mdns_mem_strdup(search->proto);
```

## Files Modified
- `patches/mdns_txt_query_fix.patch` - Patch file for the ESP-IDF mdns component
- `patches/patch_list.ini` - Added patch to the build system's patch list

## Testing
To test the fix:
1. Set up an mDNS service on a device in the local network
2. Use `AT+MDNS=2,1,<instance>,<service>,<proto>` to query for TXT records
3. Verify that the command now returns the TXT records instead of "no results found"

Example:
```
// On a Linux machine, publish an mDNS service with TXT records:
avahi-publish -s my_instance _my_printer._tcp 35 "version=v4.1.0.0" "model=ESP32"

// On ESP-AT device, query for the TXT records:
AT+MDNS=2,1,"my_instance","_my_printer","_tcp"

// Expected response (before fix would return "no results found"):
+MDNS:XXX,
IF=1
IP=0
PTR=my_instance
SRV=hostname.local:35
TXT=version=v4.1.0.0
TXT=model=ESP32
```

## Technical Details
The search structure (`mdns_search_once_t`) contains the query parameters including `instance`, `service`, and `proto`. These values come from the original AT+MDNS query command and need to be copied into the result structure so the AT command formatter can access them.

The fix uses `mdns_mem_strdup()` which is the ESP-IDF mdns component's memory allocation wrapper that ensures proper memory management.
