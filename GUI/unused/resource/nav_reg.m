% REG for NAVITAR
% Yuelong 2013-11
clear all;

% These system registers are intended to be read only
REG_SYS_PRODUCTID = uint8(1);
REG_SYS_VERSIONHW = uint8(2);
REG_SYS_VERSIONDATE = uint8(3);
REG_SYS_VERSIONSW = uint8(4);
REG_SYS_PRODUCTID_SUBCLASS = uint8(5);

% These system registers are intended to be system setup registers.
% Changing these may result in a system that does not perform properly.
REG_SETUP_ACCEL_1 = uint8(21);
REG_SETUP_ACCEL_2 = uint8(37);
REG_SETUP_INITVELOCITY_1 = uint8(22);
REG_SETUP_INITVELOCITY_2 = uint8(38);
REG_SETUP_MAXVELOCITY_1 = uint8(23);
REG_SETUP_MAXVELOCITY_2 = uint8(39);
REG_SETUP_REVBACKLASH_1 = uint8(24);
REG_SETUP_REVBACKLASH_2	= uint8(40);
REG_SETUP_FWDBACKLASH_1 = uint8(25);
REG_SETUP_FWDBACKLASH_2 = uint8(41);
REG_SETUP_CONFIG_1 = uint8(27);
REG_SETUP_CONFIG_2 = uint8(43);
REG_SETUP_LIMIT_1 = uint8(28);
REG_SETUP_LIMIT_2 = uint8(44);
REG_SETUP_WRITE = uint8(14);

% These user registers are intended for normal operation
REG_USER_TARGET_1 = uint8(16);
REG_USER_TARGET_2 = uint8(32);
REG_USER_INCREMENT_1 = uint8(17);
REG_USER_INCREMENT_2 = uint8(33);
REG_USER_CURRENT_1 = uint8(18);
REG_USER_CURRENT_2 = uint8(34);
REG_USER_LIMIT_1 = uint8(19);
REG_USER_LIMIT_2 = uint8(35);
REG_USER_STATUS_1 = uint8(20);
REG_USER_STATUS_2 = uint8(36);

% Product Type
DEF_BRIGHTLIGHT = uint16(16384);
DEF_MOTOR_CONTROLLER = uint16(16385);
DEF_MICROMO2PHASE = uint16(1);
DEF_VEXTA5PHASE = uint16(2);
DEF_DCMOTOR = uint16(3);

save('NAV_REG.mat')