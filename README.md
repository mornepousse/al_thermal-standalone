al\_thermal out-of-tree driver
==============================

`al_thermal` is the thermal sensor driver for Amazon Annapurna Labs' Alpine
SoC. Alpine SoCs are used in a few consumer products, including some QNAP NAS
appliances. This driver source code was extracted from a Linux kernel source
drop from QNAP.

This fork maintains compatibility with modern kernels.

Tested hardware
---------------

* **QNAP TS-431P** (Alpine AL-212, dual Cortex-A15, ~46-49°C typical)
* Kernel **6.12.77 LTS** (Debian Bookworm rootfs)

Features
--------

* Reads SoC die temperature via the Alpine thermal sensor unit
* Registers as a hwmon device (visible in `lm-sensors`)
* Compatible with `thermal_zone` sysfs interface

Building
--------

```bash
make -C /path/to/linux M=$(pwd)/src modules \
    ARCH=arm \
    CROSS_COMPILE=arm-linux-gnueabihf-
```

Testing
-------

A hardware test suite is included in `test/`:

```bash
bash test/run_tests.sh    # functional checks on target NAS
```
