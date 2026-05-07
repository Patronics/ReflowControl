# ReflowControl

### About

Reflow oven controller for a toaster oven, using a servo to turn the oven's power knob,
and a [MAX31855](https://www.adafruit.com/product/269) themocouple driver to monitor temperatures.

Uses a custom control board with PICAXE 20M2 originally developed for my Mech 90 project, along with an additional breakout board for the servo and thermocouple.

Optionally also uses a PICAXE 08M2 coprocessor to drive the servo to reduce timing jitter.

### Usage

To build the software, you'll need the [PicaxePreprocess](https://github.com/Patronics/PicaxePreprocess) preprocessor.

Thermal profiles are read from an i2c 24LC256 EEPROM, with the format defined by the synalize-it grammar. Editing the ProfileList.reflow.bin files is recommended to be done in [Synalize-it](https://www.synalysis.net).

To upload to the EEPROM, I recommend using [pk2cmd](https://github.com/jaka-fi/pk2cmd) with a pickit 2 or pickit 3.

To backup the EEPROM before updating it, run `./pk2cmd -P24LC256 -#0x54 -GU"./backups/backupFileName.reflow.bin"`

To upload the new file, run `./pk2cmd -P24LC256 -#0x54 -F./Path/To/ProfileList.reflow.bin -MP -YP`