#!/usr/bin/env python3
"""
BME690 environmental logger for a dry-aging fridge.

Logs temperature, humidity, pressure, and raw gas resistance once per minute
to a daily jsonl file.
"""

import json
import os
import sys
import time
from datetime import datetime

import bme690

#### CONFIG ####
LOG_DIR = os.path.expanduser("~/dry_age_monitor/logs")
INTERVAL_SECONDS = 30
WARMUP_SECONDS = 10           # let the sensor settle before recording
TEMP_OFFSET_C = -0.0          # self-heating correction; calibrate against thermometer


def connect_sensor():
    """Open the BME690 on whichever I2C address responds."""
    for addr in (bme690.I2C_ADDR_PRIMARY, bme690.I2C_ADDR_SECONDARY):
        try:
            sensor = bme690.BME690(addr)
            print(f"BME690 found at address {hex(addr)}", flush=True)
            return sensor
        except (RuntimeError, IOError):
            continue
    print("ERROR: no BME690 found at 0x76 or 0x77. Check wiring.", file=sys.stderr, flush=True)
    sys.exit(1)


def configure_sensor(sensor):
    """Configure oversampling / filter settings, and enable the gas heater."""
    sensor.set_humidity_oversample(bme690.OS_2X)
    sensor.set_pressure_oversample(bme690.OS_4X)
    sensor.set_temperature_oversample(bme690.OS_8X)
    sensor.set_filter(bme690.FILTER_SIZE_3)
    sensor.set_gas_status(bme690.ENABLE_GAS_MEAS)
    # Gas heater: 320 C for 150 ms is the library's stock profile.
    sensor.set_gas_heater_temperature(320)
    sensor.set_gas_heater_duration(150)
    sensor.select_gas_heater_profile(0)

def daily_path():
    """Return today's JSONL file path, e.g. ~/logs/2026-07-14.jsonl"""
    fname = datetime.now().strftime("%Y-%m-%d") + ".jsonl"
    return os.path.join(LOG_DIR, fname)


def read_row(sensor):
    """Take one reading. Returns a dict of the reading, or None if not ready."""
    if not sensor.get_sensor_data():
        return None
    d = sensor.data
    ts = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    # gas_resistance is only meaningful when heat_stable is True; else null
    gas = round(d.gas_resistance) if getattr(d, "heat_stable", False) else None
    return {
        "timestamp": ts,
        "temperature_c": round(d.temperature + TEMP_OFFSET_C, 2),
        "humidity_pct": round(d.humidity, 2),
        "pressure_hpa": round(d.pressure, 2),
        "gas_ohms": gas,
    }


def write_row(row):
    """Append one JSON object as a line to today's file."""
    path = daily_path()
    with open(path, "a") as f:
        f.write(json.dumps(row) + "\n")
        f.flush()
        os.fsync(f.fileno())   # force to disk so a power cut loses at most this line


def main():
    os.makedirs(LOG_DIR, exist_ok=True)
    sensor = connect_sensor()
    configure_sensor(sensor)

    print(f"Warming up for {WARMUP_SECONDS}s before logging...", flush=True)
    warm_end = time.time() + WARMUP_SECONDS
    while time.time() < warm_end:
        sensor.get_sensor_data()   # keep polling so the heater stabilises
        time.sleep(2)

    print(f"Logging every {INTERVAL_SECONDS}s to {LOG_DIR}", flush=True)
    while True:
        start = time.time()
        row = read_row(sensor)
        if row is not None:
            try:
                write_row(row)
            except OSError as e:
                # Don't die on a transient write error (e.g. USB drive hiccup)
                print(f"WARN: write failed: {e}", file=sys.stderr, flush=True)
        # Sleep the remainder of the interval, accounting for read time
        elapsed = time.time() - start
        time.sleep(max(0, INTERVAL_SECONDS - elapsed))

if __name__ == "__main__":
    main()
