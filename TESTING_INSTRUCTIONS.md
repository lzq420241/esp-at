# Testing Instructions for mDNS TXT Query Fix

## Prerequisites
1. ESP-AT firmware built with the mDNS fix patch
2. A device publishing mDNS services on the same local network
3. Serial terminal connected to ESP-AT device

## Test Setup

### Option 1: Using Linux/macOS with Avahi
On a Linux or macOS machine in the same network:

```bash
# Install avahi-utils (if not already installed)
# On Ubuntu/Debian:
sudo apt-get install avahi-utils

# On macOS, avahi is pre-installed as Bonjour

# Publish a test mDNS service with TXT records:
avahi-publish -s my_test_device _my_printer._tcp 631 "version=v4.1.0.0" "model=ESP32" "status=ready"
```

### Option 2: Using Windows with Bonjour
1. Install Bonjour Service (comes with iTunes or standalone)
2. Use dns-sd command:
```cmd
dns-sd -R my_test_device _my_printer._tcp . 631 "version=v4.1.0.0" "model=ESP32"
```

### Option 3: Using another ESP32 device
Program another ESP32 with code to advertise an mDNS service:

```c
#include "mdns.h"

void app_main() {
    // Initialize mDNS
    mdns_init();
    mdns_hostname_set("esp32-test");
    mdns_instance_name_set("My Test Device");
    
    // Add service with TXT records
    mdns_txt_item_t txt_records[] = {
        {"version", "v4.1.0.0"},
        {"model", "ESP32"},
        {"status", "ready"}
    };
    
    mdns_service_add(NULL, "_my_printer", "_tcp", 631, txt_records, 3);
}
```

## Test Procedure

### Test 1: PTR Query (should work before and after fix)
This verifies basic mDNS functionality:

```
AT+CWMODE=1
AT+CWJAP="your_ssid","your_password"

// Wait for connection...
// Query for PTR records (list all _my_printer._tcp services)
AT+MDNS=2,0,"_my_printer","_tcp"

Expected output:
+MDNS:XXX,
IF=1
IP=0
PTR=my_test_device
SRV=hostname.local:631
TXT=version=v4.1.0.0
TXT=model=ESP32
TXT=status=ready
A=192.168.x.x

OK
```

### Test 2: TXT Query (THIS IS THE FIX)
This tests the specific bug that was fixed:

```
// Query for TXT records of specific instance
AT+MDNS=2,1,"my_test_device","_my_printer","_tcp"

BEFORE FIX:
mdns is querying TXT with my_test_device._my_printer._tcp.local in 5000ms...
no results found
ERROR

AFTER FIX:
+MDNS:XXX,
IF=1
IP=0
PTR=my_test_device
SRV=hostname.local:631
TXT=version=v4.1.0.0
TXT=model=ESP32
TXT=status=ready

OK
```

### Test 3: SRV Query (should work before and after)
```
AT+MDNS=2,2,"my_test_device","_my_printer","_tcp"

Expected output:
+MDNS:XXX,
IF=1
IP=0
PTR=my_test_device
SRV=hostname.local:631

OK
```

### Test 4: Combined TXT+SRV Query
```
AT+MDNS=2,3,"my_test_device","_my_printer","_tcp"

Expected output:
+MDNS:XXX,
IF=1
IP=0
PTR=my_test_device
SRV=hostname.local:631
TXT=version=v4.1.0.0
TXT=model=ESP32
TXT=status=ready

OK
```

## Verification with Wireshark

To verify mDNS packets are being sent/received:

1. Start Wireshark on the same network interface
2. Apply filter: `mdns`
3. Execute the AT+MDNS command
4. You should see:
   - mDNS query packet from ESP32 (type=TXT)
   - mDNS response packet with TXT records

Before the fix, Wireshark would show the response packet, but the AT command would return "no results found". After the fix, both Wireshark and the AT command should show the TXT records.

## Expected Behavior Summary

| Query Type | Before Fix | After Fix |
|------------|------------|-----------|
| AT+MDNS=2,0 (PTR) | ✅ Works | ✅ Works |
| AT+MDNS=2,1 (TXT) | ❌ "no results found" | ✅ Returns TXT records |
| AT+MDNS=2,2 (SRV) | ✅ Works | ✅ Works |
| AT+MDNS=2,3 (TXT+SRV) | ⚠️ Partial (no TXT) | ✅ Returns both |

## Troubleshooting

### No results at all (before or after fix)
- Check that both devices are on the same network
- Check that mDNS service is actually running on the test device
- Verify firewall settings allow mDNS (UDP port 5353)
- Try restarting both devices

### Wireshark shows packets but AT command returns nothing
- This was the original bug - apply the fix
- If fix is applied and still doesn't work, check AT command syntax
- Verify the instance name, service type, and protocol match exactly

### Build fails with patch error
- Check that `CONFIG_AT_MDNS_COMMAND_SUPPORT` is enabled
- Verify patch_list.ini includes the mdns_txt_query_fix.patch entry
- Check that the managed_components/espressif__mdns path exists after component download
