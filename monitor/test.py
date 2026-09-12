import bme690
import time

try:
    sensor = bme690.BME690(bme690.I2C_ADDR_PRIMARY)   # 0x76
except (RuntimeError, IOError):
    sensor = bme690.BME690(bme690.I2C_ADDR_SECONDARY) # 0x77

# Oversampling / filter settings (sane defaults)
sensor.set_humidity_oversample(bme690.OS_2X)
sensor.set_temperature_oversample(bme690.OS_8X)
sensor.set_filter(bme690.FILTER_SIZE_3)

while True:
    if sensor.get_sensor_data():
        print(f"{sensor.data.temperature:.2f} C  "
              f"{sensor.data.humidity:.2f} %RH  "
              f"{sensor.data.pressure:.2f} hPa")
    time.sleep(2)
