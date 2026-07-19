# rpi dry-age-monitor

A project monitoring a home dry aging fridge setup.

## hardware list

- Raspberry Pi Zero 2 WH (with microSD card, power supply etc)
    - (the smallest pi that runs linux)
- [Pimoroni BME690 sensor board](https://www.pishop.ca/product/bme690-4-in-1-air-quality-breakout-gas-temperature-pressure-humidity/)
- [Adafruit Stemma/QT 5 port hub](https://www.adafruit.com/product/5625)
- [Adafruit Qwic -> female sockets cable](https://www.adafruit.com/product/4397)
- [Adafruit Qt to Qt cable, 400mm](https://www.adafruit.com/product/5385)
- [USB fan](https://www.amazon.ca/dp/B06Y5WWBHH?th=1)
- velcro cable ties (for securing the BME690 sensor to the fridge rack)
- [dedicated fridge](https://www.costco.ca/frigidaire-21-in.-6.0-cu-ft.-commercial-glass-display-refrigerator.product.4000409375.html), ideally with wire racks
- [12V computer case fan](https://www.canadacomputers.com/en/case-fans/249387/be-quiet-pure-wings-3-120mm-case-fan-bl104.html) fan
- [12V PWM Fan Controller](https://www.amazon.ca/dp/B0DPZM7T3Q) cheap usb-c case fan controller
- [TempPro TP50](https://temppro.com/products/tp50-digital-indoor-hygrometer-thermometer) indoor thermohygrometer (as a backup system)
- [Foam tape](https://www.amazon.ca/dp/B00448HIT0) for insulating cable gaps in the door gasket

## setup notes

### basic raspberry pi setup

- OS: [DietPi](https://dietpi.com/), which runs Debian Trixie, in this case. No particular reasoning other than past familiarity.
- Use [BalenaEtcher](https://github.com/balena-io/etcher) to install the OS onto the microSD card, and configure DietPi wifi.txt details on the SD card.
- Put SD card in Raspberry Pi and plug in power, which automatically starts the Pi.
- SSH into the Pi, ideally by finding the IP address of the Pi on your router software and then using default creds.
- Do first time setup, including:
    - name the device ("relicanth" is an especially ancient long-lived Hoenn pokemon)
    - configure Tailscale for home networking
    - set up a new user and password

### hardware setup

- Use Qwic-to-female-sockets cable to connect Stemma/QT hub to the Pi.
    - The female sockets go onto the Pi's GPIO header pins (https://pinout.xyz/ is a good reference), in this case:
        - Black (GND) -> pin 6
        - Red (3.3V) -> pin 1
        - Blue (SDA) -> pin 3
        - Yellow (SCL) -> pin 5
    - Qt end of cable plugs into the Stemma/QT hub. In theory, could plug directly into BME690 sensor, but the hub is useful for two reasons:
        - enables using a much longer Qt-to-QT cable (400mm) which helps put the sensor deeper inside the fridge
        - enables setting up fan controls via I2C later, which should be helpful down the road

- Use long QT-to-QT cable (400mm) to connect from hub to BME690 sensor

- Configure the Pi to read the sensor (`sudo apt update && sudo apt install -y i2c-tools`)
- Test that everything was plugged in correctly (`sudo i2cdetect -y 1`). BME690 sensor should be found at the address 0x76, so if everything is plugged in correctly this will return:
    ```
    tan@relicanth:~$ sudo i2cdetect -y 1
        0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    00:                         -- -- -- -- -- -- -- --
    10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    70: -- -- -- -- -- -- 76 --
    ```
    - I needed to also add /usr/sbin to my user PATH to get this to work (add `export PATH="$PATH:/usr/sbin:/sbin"` to ~/.bashrc and then run `source ~/.bashrc`)
    - I also needed to add myself to the `i2c` group (`sudo usermod -aG i2c tan`)
    - I also plugged blue and yellow on the wrong pins the first time, like a dummy.

### monitor software

- Install [uv](https://docs.astral.sh/uv/getting-started/installation/) for managing python
    - uv is better than system python install / far less pain, I've found
- Copy contents of monitor/ to a folder in home directory (can use scp or just create files manually with vim etc)
- Run `uv sync` in the folder to install dependencies.
- Run `uv run test.py` to make sure the sensor + library are working.
- Configure variables in main.py and make sure it corresponds to locations in dry-age-monitor.service
- Copy dry-age-monitor.service to systemd and enable it:
    ```
    sudo cp dry-age-monitor.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now dry-age-monitor.service
    systemctl status dry-age-monitor.service
    journalctl -u dry-age-monitor.service -f
    ```

### report

Report has been tweaked a lot but obviously for me was easier to write in R. It's
automated as a dockerized cronjob that isn't run on the Pi because the Pi doesn't
have enough memory/cpu to do it efficiently.

## monitoring and adjusting based on the data

- My goal is to keep the mean temperature between 34 and 38F, and to keep the
relative humidity between 75 and 85%. Thus far, I've found that the fridge swings
pretty wildly temperature-wise: it drops below freezing (~30F) and rises above
"danger zone" (all the way to ~44F) in a single compressor cycle. I've been trying
to mitigate this by adding more air circulation and more thermal mass - that has
mostly helped with keeping the bottom end of the temperature from dropping too low,
but hasn't really helped with the top end. I think it's because the compressor
only clicks on when it thinks fridge temp has hit ~42F. Fixing that would take
a good amount more effort since I'd need to rewire the compressor or take over
for the sensor, but I think the mean temp has sat around the target line.

- I did move the meat from the top third to the bottom third of the fridge to try
and keep the meat mostly colder than the "danger zone" and that made me feel better
about relative risk.

- Humidity also swings a lot and is sitting really high through the first week.
The meat is definitely giving off a lot of the humidity right now so I'm not overly
worried, but I did add a tray of salt to try and control the mean humidity down
a little. Not sure that's working but I know that as the meat dries out and forms
the pellicle the humidity will drop, so I will have the opposite problem towards
the end of trying to maintain _enough_ humidity.

- I was worried about the fridge being _too_ humid to the point of condensation on
the walls - the 80th to 95th percentile range of fridge humidity is peaking over 100%.
I think I'm okay with where that sits for now, but I did try recalibrating the sensor:
it was reading a little lower than what it should have compared to my
Combustion probe thermometer (and I found the TempPro thermohygrometer to be kind
of trash quality). Thus far, I'm not _seeing_ condensation build up on the sides
of the fridge (either water or ice) so I'm probably just eyeball monitoring that
for now.

- I started with a cheap USB powered desktop fan but the cable was too thick and
caused air leaks, so I switched to a case fan with standalone controller and that
is both stronger and has a thinner cable. I'm not controlling the case fan with
my Pi yet but I think I could eventually do that if I cared to. There are some
diminishing returns on it though, the more fan speed I have the more wildly the
temperature and humidity vary. I think this is mostly due to the sensor sensitivity.

## todo

- add more thermal mass to fridge to reduce temperature swings
