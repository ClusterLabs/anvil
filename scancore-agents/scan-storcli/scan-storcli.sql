-- This is the database schema for the 'storcli Scan Agent'.
--       
--       Things that change rarely should go in the main tables (even if we won't explicitely watch for them
--       to change with specific alerts).

-- ------------------------------------------------------------------------------------------------------- --
-- Adapter                                                                                                 --
-- ------------------------------------------------------------------------------------------------------- --

-- Here is the basic controller information. All connected devices will reference back to this table's 
-- 'storcli_controller_serial_number' column.

-- Key variables;
-- - "ROC temperature"
CREATE TABLE scan_storcli_controllers (
    scan_storcli_controller_uuid             uuid                        not null    primary key,
    scan_storcli_controller_host_uuid        uuid                        not null,
    scan_storcli_controller_serial_number    text                        not null,                -- This is the core identifier
    scan_storcli_controller_model            text                        not null,                -- "model"
    scan_storcli_controller_alarm_state      text                        not null,                -- "alarm_state"
    scan_storcli_controller_cache_size       numeric                     not null,                -- "on_board_memory_size"
    modified_date                            timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_controller_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_storcli_controllers OWNER TO admin;

CREATE TABLE history.scan_storcli_controllers (
    history_id                               bigserial,
    scan_storcli_controller_uuid             uuid,
    scan_storcli_controller_host_uuid        uuid,
    scan_storcli_controller_serial_number    text,
    scan_storcli_controller_model            text,
    scan_storcli_controller_alarm_state      text,
    scan_storcli_controller_cache_size       numeric,
    modified_date                            timestamp with time zone
);
ALTER TABLE history.scan_storcli_controllers OWNER TO admin;

CREATE FUNCTION history_scan_storcli_controllers() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_controllers RECORD;
BEGIN
    SELECT INTO history_scan_storcli_controllers * FROM scan_storcli_controllers WHERE scan_storcli_controller_uuid=new.scan_storcli_controller_uuid;
    INSERT INTO history.scan_storcli_controllers
        (scan_storcli_controller_uuid, 
         scan_storcli_controller_host_uuid, 
         scan_storcli_controller_serial_number, 
         scan_storcli_controller_model, 
         scan_storcli_controller_alarm_state, 
         scan_storcli_controller_cache_size, 
         modified_date)
    VALUES
        (history_scan_storcli_controllers.scan_storcli_controller_uuid,
         history_scan_storcli_controllers.scan_storcli_controller_host_uuid,
         history_scan_storcli_controllers.scan_storcli_controller_serial_number, 
         history_scan_storcli_controllers.scan_storcli_controller_model, 
         history_scan_storcli_controllers.scan_storcli_controller_alarm_state, 
         history_scan_storcli_controllers.scan_storcli_controller_cache_size, 
         history_scan_storcli_controllers.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_controllers() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_controllers
    AFTER INSERT OR UPDATE ON scan_storcli_controllers
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_controllers();


-- ------------------------------------------------------------------------------------------------------- --
-- Cachevault                                                                                              --
-- ------------------------------------------------------------------------------------------------------- --

-- Key variables;
-- - "Temperature"
-- - "Capacitance"
-- - "Pack Energy"
-- - "Next Learn time"
-- This records the basic information about the cachevault (FBU) unit.
CREATE TABLE scan_storcli_cachevaults (
    scan_storcli_cachevault_uuid                  uuid                        not null    primary key,
    scan_storcli_cachevault_host_uuid             uuid                        not null,
    scan_storcli_cachevault_controller_uuid       uuid                        not null,
    scan_storcli_cachevault_serial_number         text                        not null,                -- "Serial Number"
    scan_storcli_cachevault_state                 text                        not null,                -- "State"
    scan_storcli_cachevault_design_capacity       text                        not null,                -- "Design Capacity"
    scan_storcli_cachevault_replacement_needed    text                        not null,                -- "Replacement required"
    scan_storcli_cachevault_type                  text                        not null,                -- "Type"
    scan_storcli_cachevault_model                 text                        not null,                -- "Device Name"
    scan_storcli_cachevault_manufacture_date      text                        not null,                -- "Date of Manufacture"
    modified_date                                 timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_cachevault_host_uuid) REFERENCES hosts(host_uuid),
    FOREIGN KEY(scan_storcli_cachevault_controller_uuid) REFERENCES scan_storcli_controllers(scan_storcli_controller_uuid)
);
ALTER TABLE scan_storcli_cachevaults OWNER TO admin;

CREATE TABLE history.scan_storcli_cachevaults (
    history_id                                    bigserial,
    scan_storcli_cachevault_uuid                  uuid,
    scan_storcli_cachevault_host_uuid             uuid,
    scan_storcli_cachevault_controller_uuid       uuid,
    scan_storcli_cachevault_serial_number         text,
    scan_storcli_cachevault_state                 text,
    scan_storcli_cachevault_design_capacity       text,
    scan_storcli_cachevault_replacement_needed    text,
    scan_storcli_cachevault_type                  text,
    scan_storcli_cachevault_model                 text,
    scan_storcli_cachevault_manufacture_date      text,
    modified_date                                 timestamp with time zone
);
ALTER TABLE history.scan_storcli_cachevaults OWNER TO admin;

CREATE FUNCTION history_scan_storcli_cachevaults() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_cachevaults RECORD;
BEGIN
    SELECT INTO history_scan_storcli_cachevaults * FROM scan_storcli_cachevaults WHERE scan_storcli_cachevault_uuid=new.scan_storcli_cachevault_uuid;
    INSERT INTO history.scan_storcli_cachevaults
        (scan_storcli_cachevault_uuid, 
         scan_storcli_cachevault_host_uuid,
         scan_storcli_cachevault_controller_uuid, 
         scan_storcli_cachevault_serial_number, 
         scan_storcli_cachevault_state, 
         scan_storcli_cachevault_design_capacity, 
         scan_storcli_cachevault_replacement_needed, 
         scan_storcli_cachevault_type, 
         scan_storcli_cachevault_model, 
         scan_storcli_cachevault_manufacture_date, 
         modified_date)
    VALUES
        (history_scan_storcli_cachevaults.scan_storcli_cachevault_uuid,
         history_scan_storcli_cachevaults.scan_storcli_cachevault_host_uuid,
         history_scan_storcli_cachevaults.scan_storcli_cachevault_controller_uuid, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_serial_number, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_state, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_design_capacity, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_replacement_needed, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_type, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_model, 
         history_scan_storcli_cachevaults.scan_storcli_cachevault_manufacture_date, 
         history_scan_storcli_cachevaults.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_cachevaults() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_cachevaults
    AFTER INSERT OR UPDATE ON scan_storcli_cachevaults
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_cachevaults();


-- ------------------------------------------------------------------------------------------------------- --
-- Battery Backup Units                                                                                    --
-- ------------------------------------------------------------------------------------------------------- --

-- Key variables;
-- - "Temperature"
-- - "Absolute state of charge"
-- - "Cycle Count"
-- - "Full Charge Capacity"
-- - "Fully Charged"
-- - "Learn Cycle Active"
-- - "Next Learn time"
-- - "Over Charged"
-- - "Over Temperature"
-- This records the basic information about the cachevault (FBU) unit.
CREATE TABLE scan_storcli_bbus (
    scan_storcli_bbu_uuid                  uuid                        not null    primary key,
    scan_storcli_bbu_host_uuid             uuid                        not null,
    scan_storcli_bbu_controller_uuid       uuid                        not null,
    scan_storcli_bbu_serial_number         text                        not null,                -- "Serial Number"
    scan_storcli_bbu_type                  text                        not null,                -- "Type"
    scan_storcli_bbu_model                 text                        not null,                -- "Manufacture Name"
    scan_storcli_bbu_state                 text                        not null,                -- "Battery State"
    scan_storcli_bbu_manufacture_date      text                        not null,                -- "Date of Manufacture"
    scan_storcli_bbu_design_capacity       text                        not null,                -- "Design Capacity"
    scan_storcli_bbu_replacement_needed    text                        not null,                -- "Pack is about to fail & should be replaced"
    modified_date                          timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_bbu_host_uuid) REFERENCES hosts(host_uuid),
    FOREIGN KEY(scan_storcli_bbu_controller_uuid) REFERENCES scan_storcli_controllers(scan_storcli_controller_uuid)
);
ALTER TABLE scan_storcli_bbus OWNER TO admin;

CREATE TABLE history.scan_storcli_bbus (
    history_id                             bigserial,
    scan_storcli_bbu_uuid                  uuid,
    scan_storcli_bbu_host_uuid             uuid,
    scan_storcli_bbu_controller_uuid       uuid,
    scan_storcli_bbu_serial_number         text,
    scan_storcli_bbu_type                  text,
    scan_storcli_bbu_model                 text,
    scan_storcli_bbu_state                 text,
    scan_storcli_bbu_manufacture_date      text,
    scan_storcli_bbu_design_capacity       text,
    scan_storcli_bbu_replacement_needed    text,
    modified_date                          timestamp with time zone
);
ALTER TABLE history.scan_storcli_bbus OWNER TO admin;

CREATE FUNCTION history_scan_storcli_bbus() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_bbus RECORD;
BEGIN
    SELECT INTO history_scan_storcli_bbus * FROM scan_storcli_bbus WHERE scan_storcli_bbu_uuid=new.scan_storcli_bbu_uuid;
    INSERT INTO history.scan_storcli_bbus
        (scan_storcli_bbu_uuid, 
         scan_storcli_bbu_host_uuid, 
         scan_storcli_bbu_controller_uuid, 
         scan_storcli_bbu_serial_number, 
         scan_storcli_bbu_type, 
         scan_storcli_bbu_model, 
         scan_storcli_bbu_state, 
         scan_storcli_bbu_manufacture_date, 
         scan_storcli_bbu_design_capacity, 
         scan_storcli_bbu_replacement_needed, 
         modified_date)
    VALUES
        (history_scan_storcli_bbus.scan_storcli_bbu_uuid,
         history_scan_storcli_bbus.scan_storcli_bbu_host_uuid, 
         history_scan_storcli_bbus.scan_storcli_bbu_controller_uuid, 
         history_scan_storcli_bbus.scan_storcli_bbu_serial_number, 
         history_scan_storcli_bbus.scan_storcli_bbu_type, 
         history_scan_storcli_bbus.scan_storcli_bbu_model, 
         history_scan_storcli_bbus.scan_storcli_bbu_state, 
         history_scan_storcli_bbus.scan_storcli_bbu_manufacture_date, 
         history_scan_storcli_bbus.scan_storcli_bbu_design_capacity, 
         history_scan_storcli_bbus.scan_storcli_bbu_replacement_needed, 
         history_scan_storcli_bbus.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_bbus() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_bbus
    AFTER INSERT OR UPDATE ON scan_storcli_bbus
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_bbus();


-- ------------------------------------------------------------------------------------------------------- --
-- Virtual Drives                                                                                          --
-- ------------------------------------------------------------------------------------------------------- --

-- This records the basic virtual drives. These contain one or more drive groups to form an array
CREATE TABLE scan_storcli_virtual_drives (
    scan_storcli_virtual_drive_uuid                 uuid                        not null    primary key,
    scan_storcli_virtual_drive_host_uuid            uuid                        not null,
    scan_storcli_virtual_drive_controller_uuid      uuid                        not null,
    scan_storcli_virtual_drive_id_string            text                        not null,                -- This is '<host_controller_sn>-vd<x>' where 'x' is the virtual drive number.
    scan_storcli_virtual_drive_creation_date        text                        not null,                -- "Creation Date" and "Creation Time"
    scan_storcli_virtual_drive_data_protection      text                        not null,                -- "Data Protection"
    scan_storcli_virtual_drive_disk_cache_policy    text                        not null,                -- "Disk Cache Policy"
    scan_storcli_virtual_drive_emulation_type       text                        not null,                -- "Emulation type"
    scan_storcli_virtual_drive_encryption           text                        not null,                -- "Encryption"
    scan_storcli_virtual_drive_blocks               numeric                     not null,                -- "Number of Blocks"
    scan_storcli_virtual_drive_strip_size           text                        not null,                -- "Strip Size" (has the suffix 'Bytes', so not numeric)
    scan_storcli_virtual_drive_drives_per_span      numeric                     not null,                -- "Number of Drives Per Span"
    scan_storcli_virtual_drive_span_depth           numeric                     not null,                -- "Span Depth"
    scan_storcli_virtual_drive_scsi_naa_id          text                        not null,                -- "SCSI NAA Id" - https://en.wikipedia.org/wiki/ISCSI#Addressing
    modified_date                                   timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_virtual_drive_host_uuid) REFERENCES hosts(host_uuid),
    FOREIGN KEY(scan_storcli_virtual_drive_controller_uuid) REFERENCES scan_storcli_controllers(scan_storcli_controller_uuid)
);
ALTER TABLE scan_storcli_virtual_drives OWNER TO admin;

CREATE TABLE history.scan_storcli_virtual_drives (
    history_id                                      bigserial,
    scan_storcli_virtual_drive_uuid                 uuid,
    scan_storcli_virtual_drive_host_uuid            uuid,
    scan_storcli_virtual_drive_controller_uuid      uuid,
    scan_storcli_virtual_drive_id_string            text,
    scan_storcli_virtual_drive_creation_date        text,
    scan_storcli_virtual_drive_data_protection      text,
    scan_storcli_virtual_drive_disk_cache_policy    text,
    scan_storcli_virtual_drive_emulation_type       text,
    scan_storcli_virtual_drive_encryption           text,
    scan_storcli_virtual_drive_blocks               numeric,
    scan_storcli_virtual_drive_strip_size           text,
    scan_storcli_virtual_drive_drives_per_span      numeric,
    scan_storcli_virtual_drive_span_depth           numeric,
    scan_storcli_virtual_drive_scsi_naa_id          text,
    modified_date                                   timestamp with time zone
);
ALTER TABLE history.scan_storcli_virtual_drives OWNER TO admin;

CREATE FUNCTION history_scan_storcli_virtual_drives() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_virtual_drives RECORD;
BEGIN
    SELECT INTO history_scan_storcli_virtual_drives * FROM scan_storcli_virtual_drives WHERE scan_storcli_virtual_drive_uuid=new.scan_storcli_virtual_drive_uuid;
    INSERT INTO history.scan_storcli_virtual_drives
        (scan_storcli_virtual_drive_uuid, 
         scan_storcli_virtual_drive_host_uuid, 
         scan_storcli_virtual_drive_controller_uuid, 
         scan_storcli_virtual_drive_id_string, 
         scan_storcli_virtual_drive_creation_date, 
         scan_storcli_virtual_drive_data_protection, 
         scan_storcli_virtual_drive_disk_cache_policy, 
         scan_storcli_virtual_drive_emulation_type, 
         scan_storcli_virtual_drive_encryption, 
         scan_storcli_virtual_drive_blocks, 
         scan_storcli_virtual_drive_strip_size, 
         scan_storcli_virtual_drive_drives_per_span, 
         scan_storcli_virtual_drive_span_depth, 
         scan_storcli_virtual_drive_scsi_naa_id, 
         modified_date)
    VALUES
        (history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_uuid,
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_host_uuid, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_controller_uuid, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_id_string, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_creation_date, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_data_protection, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_disk_cache_policy, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_emulation_type, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_encryption, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_blocks, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_strip_size, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_drives_per_span, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_span_depth, 
         history_scan_storcli_virtual_drives.scan_storcli_virtual_drive_scsi_naa_id, 
         history_scan_storcli_virtual_drives.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_virtual_drives() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_virtual_drives
    AFTER INSERT OR UPDATE ON scan_storcli_virtual_drives
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_virtual_drives();


-- ------------------------------------------------------------------------------------------------------- --
-- Drive Groups                                                                                            --
-- ------------------------------------------------------------------------------------------------------- --

-- This records the basic drive group information.
CREATE TABLE scan_storcli_drive_groups (
    scan_storcli_drive_group_uuid                  uuid                        not null    primary key,
    scan_storcli_drive_group_host_uuid             uuid                        not null,
    scan_storcli_drive_group_virtual_drive_uuid    uuid                        not null,
    scan_storcli_drive_group_id_string             text                        not null,                -- This is '<host_controller_sn>-vd<x>-dg<y>' where 'x' is the virtual drive number and 'y' is the drive group number.
    scan_storcli_drive_group_access                text                        not null,                -- "access"
    scan_storcli_drive_group_array_size            text                        not null,                -- "array_size"
    scan_storcli_drive_group_array_state           text                        not null,                -- "array_state"
    scan_storcli_drive_group_cache                 text                        not null,                -- "cache"
    scan_storcli_drive_group_cachecade             text                        not null,                -- "cachecade"
    scan_storcli_drive_group_consistent            text                        not null,                -- "consistent"
    scan_storcli_drive_group_disk_cache            text                        not null,                -- "disk_cache"
    scan_storcli_drive_group_raid_type             text                        not null,                -- "raid_type"
    scan_storcli_drive_group_read_cache            text                        not null,                -- "read_cache"
    scan_storcli_drive_group_scheduled_cc          text                        not null,                -- "scheduled_consistency_check"
    scan_storcli_drive_group_write_cache           text                        not null,                -- "write_cache"
    modified_date                                  timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_drive_group_host_uuid) REFERENCES hosts(host_uuid),
    FOREIGN KEY(scan_storcli_drive_group_virtual_drive_uuid) REFERENCES scan_storcli_virtual_drives(scan_storcli_virtual_drive_uuid)
);
ALTER TABLE scan_storcli_drive_groups OWNER TO admin;

CREATE TABLE history.scan_storcli_drive_groups (
    history_id                                     bigserial,
    scan_storcli_drive_group_uuid                  uuid,
    scan_storcli_drive_group_host_uuid             uuid,
    scan_storcli_drive_group_virtual_drive_uuid    uuid,
    scan_storcli_drive_group_id_string             text,
    scan_storcli_drive_group_access                text,
    scan_storcli_drive_group_array_size            text,
    scan_storcli_drive_group_array_state           text,
    scan_storcli_drive_group_cache                 text,
    scan_storcli_drive_group_cachecade             text,
    scan_storcli_drive_group_consistent            text,
    scan_storcli_drive_group_disk_cache            text,
    scan_storcli_drive_group_raid_type             text,
    scan_storcli_drive_group_read_cache            text,
    scan_storcli_drive_group_scheduled_cc          text,
    scan_storcli_drive_group_write_cache           text,
    modified_date                                  timestamp with time zone
);
ALTER TABLE history.scan_storcli_drive_groups OWNER TO admin;

CREATE FUNCTION history_scan_storcli_drive_groups() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_drive_groups RECORD;
BEGIN
    SELECT INTO history_scan_storcli_drive_groups * FROM scan_storcli_drive_groups WHERE scan_storcli_drive_group_uuid=new.scan_storcli_drive_group_uuid;
    INSERT INTO history.scan_storcli_drive_groups
        (scan_storcli_drive_group_uuid, 
         scan_storcli_drive_group_host_uuid, 
         scan_storcli_drive_group_virtual_drive_uuid, 
         scan_storcli_drive_group_id_string, 
         scan_storcli_drive_group_access, 
         scan_storcli_drive_group_array_size, 
         scan_storcli_drive_group_array_state, 
         scan_storcli_drive_group_cache, 
         scan_storcli_drive_group_cachecade, 
         scan_storcli_drive_group_consistent, 
         scan_storcli_drive_group_disk_cache, 
         scan_storcli_drive_group_raid_type, 
         scan_storcli_drive_group_read_cache, 
         scan_storcli_drive_group_scheduled_cc, 
         scan_storcli_drive_group_write_cache, 
         modified_date)
    VALUES
        (history_scan_storcli_drive_groups.scan_storcli_drive_group_uuid,
         history_scan_storcli_drive_groups.scan_storcli_drive_group_host_uuid, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_virtual_drive_uuid, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_id_string, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_access, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_array_size, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_array_state, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_cache, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_cachecade, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_consistent, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_disk_cache, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_raid_type, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_read_cache, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_scheduled_cc, 
         history_scan_storcli_drive_groups.scan_storcli_drive_group_write_cache, 
         history_scan_storcli_drive_groups.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_drive_groups() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_drive_groups
    AFTER INSERT OR UPDATE ON scan_storcli_drive_groups
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_drive_groups();


-- ------------------------------------------------------------------------------------------------------- --
-- Physical Drives                                                                                         --
-- ------------------------------------------------------------------------------------------------------- --

-- NOTE: More information to T10-PI (protection information) is available here:
--       https://www.seagate.com/files/staticfiles/docs/pdf/whitepaper/safeguarding-data-from-corruption-technology-paper-tp621us.pdf

-- This records the basic drive group information.
-- Key variables;
-- - "Drive Temperature"
-- - "spun_up"
-- - "state"
-- - "Certified"
-- - "Device Speed"
-- - "Link Speed"
-- - "sas_port_0_link_speed"
-- - "sas_port_0_port_status"
-- - "sas_port_0_sas_address"
-- - "sas_port_1_link_speed"
-- - "sas_port_1_port_status"
-- - "sas_port_1_sas_address"
-- - "drive_media"
-- - "interface"
-- - "NAND Vendor"
-- - "Firmware Revision"
-- - "World Wide Name"
-- - "device_id"
-- - "SED Enabled"
-- - "Secured"
-- - "Locked"
-- - "Needs External Key Management Attention"
-- - "protection_info", "Protection Information Eligible"
-- - "Emergency Spare"
-- - "Commissioned Spare"
-- - "S.M.A.R.T alert flagged by drive"
-- - "Media Error Count"
-- - "Other Error Count"
-- - "Predictive Failure Count"
CREATE TABLE scan_storcli_physical_drives (
    scan_storcli_physical_drive_uuid                     uuid                        not null    primary key,
    scan_storcli_physical_drive_host_uuid                uuid                        not null,
    scan_storcli_physical_drive_controller_uuid          uuid                        not null,
    scan_storcli_physical_drive_virtual_drive            text                        not null,
    scan_storcli_physical_drive_drive_group              text                        not null,
    scan_storcli_physical_drive_enclosure_id             text                        not null,
    scan_storcli_physical_drive_slot_number              text                        not null,
    scan_storcli_physical_drive_serial_number            text                        not null,                -- "Serial Number"
    scan_storcli_physical_drive_size                     text                        not null,                -- In 'text' because of 'Bytes' suffix - "drive_size" but also; "Raw size", "Non Coerced size" and "Coerced size"
    scan_storcli_physical_drive_sector_size              text                        not null,                -- In 'text' because of 'Bytes' suffix - "sector_size", "Sector Size"
    scan_storcli_physical_drive_vendor                   text                        not null,                -- "Manufacturer Identification"
    scan_storcli_physical_drive_model                    text                        not null,                -- "drive_model", "Model Number"
    scan_storcli_physical_drive_self_encrypting_drive    text                        not null,                -- "self_encrypting_drive", "SED Capable"
    modified_date                                        timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_physical_drive_host_uuid) REFERENCES hosts(host_uuid),
    FOREIGN KEY(scan_storcli_physical_drive_controller_uuid) REFERENCES scan_storcli_controllers(scan_storcli_controller_uuid)
);
ALTER TABLE scan_storcli_physical_drives OWNER TO admin;

CREATE TABLE history.scan_storcli_physical_drives (
    history_id                                           bigserial,
    scan_storcli_physical_drive_uuid                     uuid,
    scan_storcli_physical_drive_host_uuid                uuid,
    scan_storcli_physical_drive_controller_uuid          uuid,
    scan_storcli_physical_drive_serial_number            text,
    scan_storcli_physical_drive_virtual_drive            text,
    scan_storcli_physical_drive_drive_group              text,
    scan_storcli_physical_drive_enclosure_id             text,
    scan_storcli_physical_drive_slot_number              text,
    scan_storcli_physical_drive_size                     text,
    scan_storcli_physical_drive_sector_size              text,
    scan_storcli_physical_drive_vendor                   text,
    scan_storcli_physical_drive_model                    text,
    scan_storcli_physical_drive_self_encrypting_drive    text,
    modified_date                                        timestamp with time zone
);
ALTER TABLE history.scan_storcli_physical_drives OWNER TO admin;

CREATE FUNCTION history_scan_storcli_physical_drives() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_physical_drives RECORD;
BEGIN
    SELECT INTO history_scan_storcli_physical_drives * FROM scan_storcli_physical_drives WHERE scan_storcli_physical_drive_uuid=new.scan_storcli_physical_drive_uuid;
    INSERT INTO history.scan_storcli_physical_drives
        (scan_storcli_physical_drive_uuid, 
         scan_storcli_physical_drive_host_uuid,
         scan_storcli_physical_drive_controller_uuid, 
         scan_storcli_physical_drive_virtual_drive, 
         scan_storcli_physical_drive_drive_group, 
         scan_storcli_physical_drive_enclosure_id, 
         scan_storcli_physical_drive_slot_number, 
         scan_storcli_physical_drive_serial_number, 
         scan_storcli_physical_drive_size, 
         scan_storcli_physical_drive_sector_size, 
         scan_storcli_physical_drive_vendor, 
         scan_storcli_physical_drive_model, 
         scan_storcli_physical_drive_self_encrypting_drive, 
         modified_date)
    VALUES
        (history_scan_storcli_physical_drives.scan_storcli_physical_drive_uuid,
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_host_uuid,
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_controller_uuid, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_virtual_drive, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_drive_group, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_enclosure_id, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_slot_number, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_serial_number, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_size, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_sector_size, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_vendor, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_model, 
         history_scan_storcli_physical_drives.scan_storcli_physical_drive_self_encrypting_drive, 
         history_scan_storcli_physical_drives.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_physical_drives() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_physical_drives
    AFTER INSERT OR UPDATE ON scan_storcli_physical_drives
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_physical_drives();


-- ------------------------------------------------------------------------------------------------------- --
-- Each data type has several variables that we're not storing in the component-specific tables. To do so  --
-- would be to create massive tables that would miss variables not shown for all controllers or when new   --
-- variables are added or renamed. So this table is used to store all those myriade of variables. Each     --
-- entry will reference the table it is attached to and the UUID of the record in that table. The column   --

-- 'storcli_variable_is_temperature' will be used to know what data is a temperature and will be then used --
-- to inform on the host's thermal health.                                                                 --
-- ------------------------------------------------------------------------------------------------------- --

-- This stores various variables found for a given controller but not explicitely checked for (or that 
-- change frequently).
CREATE TABLE scan_storcli_variables (
    scan_storcli_variable_uuid              uuid                        not null    primary key,
    scan_storcli_variable_host_uuid         uuid                        not null,
    scan_storcli_variable_source_table      text                        not null,
    scan_storcli_variable_source_uuid       uuid                        not null,
    scan_storcli_variable_is_temperature    boolean                     not null    default FALSE,
    scan_storcli_variable_name              text                        not null,
    scan_storcli_variable_value             text                        not null,
    modified_date                           timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storcli_variable_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_storcli_variables OWNER TO admin;

CREATE TABLE history.scan_storcli_variables (
    history_id                              bigserial,
    scan_storcli_variable_uuid              uuid,
    scan_storcli_variable_host_uuid         uuid,
    scan_storcli_variable_source_table      text,
    scan_storcli_variable_source_uuid       uuid,
    scan_storcli_variable_is_temperature    boolean,
    scan_storcli_variable_name              text,
    scan_storcli_variable_value             text,
    modified_date                           timestamp with time zone
);
ALTER TABLE history.scan_storcli_variables OWNER TO admin;

CREATE FUNCTION history_scan_storcli_variables() RETURNS trigger
AS $$
DECLARE
    history_scan_storcli_variables RECORD;
BEGIN
    SELECT INTO history_scan_storcli_variables * FROM scan_storcli_variables WHERE scan_storcli_variable_uuid=new.scan_storcli_variable_uuid;
    INSERT INTO history.scan_storcli_variables
        (scan_storcli_variable_uuid, 
         scan_storcli_variable_host_uuid, 
         scan_storcli_variable_source_table, 
         scan_storcli_variable_source_uuid, 
         scan_storcli_variable_is_temperature,
         scan_storcli_variable_name,
         scan_storcli_variable_value,
         modified_date)
    VALUES
        (history_scan_storcli_variables.scan_storcli_variable_uuid,
         history_scan_storcli_variables.scan_storcli_variable_host_uuid, 
         history_scan_storcli_variables.scan_storcli_variable_source_table, 
         history_scan_storcli_variables.scan_storcli_variable_source_uuid, 
         history_scan_storcli_variables.scan_storcli_variable_is_temperature,
         history_scan_storcli_variables.scan_storcli_variable_name,
         history_scan_storcli_variables.scan_storcli_variable_value,
         history_scan_storcli_variables.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storcli_variables() OWNER TO admin;

CREATE TRIGGER trigger_scan_storcli_variables
    AFTER INSERT OR UPDATE ON scan_storcli_variables
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storcli_variables();
