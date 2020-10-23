-- This is the database schema for the 'remote-access Scan Agent'.

CREATE TABLE scan_apc_pdus (
    scan_apc_pdu_uuid                uuid                        not null    primary key,    -- This is set by the target, not by us!
    scan_apc_pdu_fence_uuid          uuid                        not null,                   -- 
    scan_apc_pdu_serial_number       text                        not null,                   -- 
    scan_apc_pdu_model_number        text                        not null,                   -- 
    scan_apc_pdu_manufacture_date    text                        not null,                   -- 
    scan_apc_pdu_firmware_version    text                        not null,                   -- 
    scan_apc_pdu_hardware_version    text                        not null,                   -- 
    scan_apc_pdu_ipv4_address        text                        not null,                   -- 
    scan_apc_pdu_mac_address         text                        not null,                   -- 
    scan_apc_pdu_mtu_size            numeric                     not null,                   -- 
    scan_apc_pdu_link_speed          numeric                     not null,                   -- in bits-per-second, set to '0' when we lose access
    scan_apc_pdu_phase_count         numeric                     not null,                   -- 
    scan_apc_pdu_outlet_count        numeric                     not null,                   -- 
    modified_date                    timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_pdu_fence_uuid) REFERENCES fences(fence_uuid)
);
ALTER TABLE scan_apc_pdus OWNER TO admin;

CREATE TABLE history.scan_apc_pdus (
    history_id                       bigserial,
    scan_apc_pdu_uuid                uuid,
    scan_apc_pdu_fence_uuid          uuid,
    scan_apc_pdu_serial_number       text,
    scan_apc_pdu_model_number        text,
    scan_apc_pdu_manufacture_date    text,
    scan_apc_pdu_firmware_version    text,
    scan_apc_pdu_hardware_version    text,
    scan_apc_pdu_ipv4_address        text,
    scan_apc_pdu_mac_address         text,
    scan_apc_pdu_mtu_size            numeric,
    scan_apc_pdu_link_speed          numeric,
    scan_apc_pdu_phase_count         numeric,
    scan_apc_pdu_outlet_count        numeric,
    modified_date                    timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_pdus OWNER TO admin;

CREATE FUNCTION history_scan_apc_pdus() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_pdus RECORD;
BEGIN
    SELECT INTO history_scan_apc_pdus * FROM scan_apc_pdus WHERE scan_apc_pdu_uuid=new.scan_apc_pdu_uuid;
    INSERT INTO history.scan_apc_pdus
        (scan_apc_pdu_uuid,
         scan_apc_pdu_fence_uuid, 
         scan_apc_pdu_serial_number, 
         scan_apc_pdu_model_number, 
         scan_apc_pdu_manufacture_date, 
         scan_apc_pdu_firmware_version, 
         scan_apc_pdu_hardware_version, 
         scan_apc_pdu_ipv4_address, 
         scan_apc_pdu_mac_address, 
         scan_apc_pdu_mtu_size, 
         scan_apc_pdu_link_speed, 
         scan_apc_pdu_phase_count, 
         scan_apc_pdu_outlet_count, 
         modified_date)
    VALUES
        (history_scan_apc_pdus.scan_apc_pdu_uuid,
         history_scan_apc_pdus.scan_apc_pdu_fence_uuid, 
         history_scan_apc_pdus.scan_apc_pdu_serial_number, 
         history_scan_apc_pdus.scan_apc_pdu_model_number, 
         history_scan_apc_pdus.scan_apc_pdu_manufacture_date, 
         history_scan_apc_pdus.scan_apc_pdu_firmware_version, 
         history_scan_apc_pdus.scan_apc_pdu_hardware_version, 
         history_scan_apc_pdus.scan_apc_pdu_ipv4_address, 
         history_scan_apc_pdus.scan_apc_pdu_mac_address, 
         history_scan_apc_pdus.scan_apc_pdu_mtu_size, 
         history_scan_apc_pdus.scan_apc_pdu_link_speed, 
         history_scan_apc_pdus.scan_apc_pdu_phase_count, 
         history_scan_apc_pdus.scan_apc_pdu_outlet_count, 
         history_scan_apc_pdus.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_pdus() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_pdus
    AFTER INSERT OR UPDATE ON scan_apc_pdus
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_pdus();


-- Phases on the PDU
CREATE TABLE scan_apc_pdu_phases (
    scan_apc_pdu_phase_uuid                 uuid                        not null    primary key,
    scan_apc_pdu_phase_scan_apc_pdu_uuid    uuid                        not null,                   -- 
    scan_apc_pdu_phase_number               text                        not null,                   -- 
    scan_apc_pdu_phase_current_amperage     numeric                     not null,                   -- Max, low/high warn and high critical will be read from the PDU in the given pass.
    scan_apc_pdu_phase_max_amperage         numeric,
    modified_date                           timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_pdu_phase_scan_apc_pdu_uuid) REFERENCES scan_apc_pdus(scan_apc_pdu_uuid)
);
ALTER TABLE scan_apc_pdu_phases OWNER TO admin;

CREATE TABLE history.scan_apc_pdu_phases (
    history_id                              bigserial,
    scan_apc_pdu_phase_uuid                 uuid,
    scan_apc_pdu_phase_scan_apc_pdu_uuid    uuid,
    scan_apc_pdu_phase_number               text,
    scan_apc_pdu_phase_current_amperage     numeric,
    scan_apc_pdu_phase_max_amperage         numeric,
    modified_date                           timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_pdu_phases OWNER TO admin;

CREATE FUNCTION history_scan_apc_pdu_phases() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_pdu_phases RECORD;
BEGIN
    SELECT INTO history_scan_apc_pdu_phases * FROM scan_apc_pdu_phases WHERE scan_apc_pdu_phase_uuid=new.scan_apc_pdu_phase_uuid;
    INSERT INTO history.scan_apc_pdu_phases
        (scan_apc_pdu_phase_uuid, 
         scan_apc_pdu_phase_scan_apc_pdu_uuid,
         scan_apc_pdu_phase_number, 
         scan_apc_pdu_phase_current_amperage, 
         scan_apc_pdu_phase_max_amperage, 
         modified_date)
    VALUES
        (history_scan_apc_pdu_phases.scan_apc_pdu_phase_uuid,
         history_scan_apc_pdu_phases.scan_apc_pdu_phase_scan_apc_pdu_uuid,
         history_scan_apc_pdu_phases.scan_apc_pdu_phase_number, 
         history_scan_apc_pdu_phases.scan_apc_pdu_phase_current_amperage, 
         history_scan_apc_pdu_phases.scan_apc_pdu_phase_max_amperage, 
         history_scan_apc_pdu_phases.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_pdu_phases() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_pdu_phases
    AFTER INSERT OR UPDATE ON scan_apc_pdu_phases
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_pdu_phases();


-- Phases on the PDU
CREATE TABLE scan_apc_pdu_outlets (
    scan_apc_pdu_outlet_uuid                 uuid                        not null    primary key,
    scan_apc_pdu_outlet_scan_apc_pdu_uuid    uuid                        not null,
    scan_apc_pdu_outlet_number               text                        not null,
    scan_apc_pdu_outlet_name                 text                        not null,
    scan_apc_pdu_outlet_on_phase             text                        not null,
    scan_apc_pdu_outlet_state                text                        not null,    -- on / off / unknown
    modified_date                            timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_pdu_outlet_scan_apc_pdu_uuid) REFERENCES scan_apc_pdus(scan_apc_pdu_uuid)
);
ALTER TABLE scan_apc_pdu_outlets OWNER TO admin;

CREATE TABLE history.scan_apc_pdu_outlets (
    history_id                               bigserial,
    scan_apc_pdu_outlet_uuid                 uuid,
    scan_apc_pdu_outlet_scan_apc_pdu_uuid    uuid,
    scan_apc_pdu_outlet_number               text,
    scan_apc_pdu_outlet_name                 text,
    scan_apc_pdu_outlet_on_phase             text,
    scan_apc_pdu_outlet_state                text,
    modified_date                            timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_pdu_outlets OWNER TO admin;

CREATE FUNCTION history_scan_apc_pdu_outlets() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_pdu_outlets RECORD;
BEGIN
    SELECT INTO history_scan_apc_pdu_outlets * FROM scan_apc_pdu_outlets WHERE scan_apc_pdu_outlet_uuid=new.scan_apc_pdu_outlet_uuid;
    INSERT INTO history.scan_apc_pdu_outlets
        (scan_apc_pdu_outlet_uuid, 
         scan_apc_pdu_outlet_scan_apc_pdu_uuid,
         scan_apc_pdu_outlet_number, 
         scan_apc_pdu_outlet_name, 
         scan_apc_pdu_outlet_on_phase, 
         scan_apc_pdu_outlet_state, 
         modified_date)
    VALUES
        (history_scan_apc_pdu_outlets.scan_apc_pdu_outlet_uuid,
         history_scan_apc_pdu_outlets.scan_apc_pdu_outlet_scan_apc_pdu_uuid,
         history_scan_apc_pdu_outlets.scan_apc_pdu_outlet_number, 
         history_scan_apc_pdu_outlets.scan_apc_pdu_outlet_name, 
         history_scan_apc_pdu_outlets.scan_apc_pdu_outlet_on_phase, 
         history_scan_apc_pdu_outlets.scan_apc_pdu_outlet_state, 
         history_scan_apc_pdu_outlets.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_pdu_outlets() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_pdu_outlets
    AFTER INSERT OR UPDATE ON scan_apc_pdu_outlets
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_pdu_outlets();


-- This stores various variables found for a given controller but not explicitely checked for (or that 
-- change frequently).
CREATE TABLE scan_apc_pdu_variables (
    scan_apc_pdu_variable_uuid                 uuid                        not null    primary key,    -- 
    scan_apc_pdu_variable_scan_apc_pdu_uuid    uuid                        not null,                   -- 
    scan_apc_pdu_variable_is_temperature       boolean                     not null,                   -- 
    scan_apc_pdu_variable_name                 text                        not null,                   -- 
    scan_apc_pdu_variable_value                text                        not null,                   -- 
    modified_date                              timestamp with time zone    not null,                   -- 
    
    FOREIGN KEY(scan_apc_pdu_variable_scan_apc_pdu_uuid) REFERENCES scan_apc_pdus(scan_apc_pdu_uuid)
);
ALTER TABLE scan_apc_pdu_variables OWNER TO admin;

CREATE TABLE history.scan_apc_pdu_variables (
    history_id                                 bigserial,
    scan_apc_pdu_variable_uuid                 uuid,
    scan_apc_pdu_variable_scan_apc_pdu_uuid    uuid,
    scan_apc_pdu_variable_is_temperature       boolean,
    scan_apc_pdu_variable_name                 text,
    scan_apc_pdu_variable_value                text,
    modified_date                              timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_pdu_variables OWNER TO admin;

CREATE FUNCTION history_scan_apc_pdu_variables() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_pdu_variables RECORD;
BEGIN
    SELECT INTO history_scan_apc_pdu_variables * FROM scan_apc_pdu_variables WHERE scan_apc_pdu_variable_uuid=new.scan_apc_pdu_variable_uuid;
    INSERT INTO history.scan_apc_pdu_variables
        (scan_apc_pdu_variable_uuid, 
         scan_apc_pdu_variable_scan_apc_pdu_uuid, 
         scan_apc_pdu_variable_is_temperature,
         scan_apc_pdu_variable_name,
         scan_apc_pdu_variable_value,
         modified_date)
    VALUES
        (history_scan_apc_pdu_variables.scan_apc_pdu_variable_uuid,
         history_scan_apc_pdu_variables.scan_apc_pdu_variable_scan_apc_pdu_uuid, 
         history_scan_apc_pdu_variables.scan_apc_pdu_variable_is_temperature,
         history_scan_apc_pdu_variables.scan_apc_pdu_variable_name,
         history_scan_apc_pdu_variables.scan_apc_pdu_variable_value,
         history_scan_apc_pdu_variables.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_pdu_variables() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_pdu_variables
    AFTER INSERT OR UPDATE ON scan_apc_pdu_variables
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_pdu_variables();
