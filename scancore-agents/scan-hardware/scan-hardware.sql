-- This is the database schema for the 'scan-hardware Scan Agent'.

CREATE TABLE scan_hardware (
    scan_hardware_uuid            uuid                        primary key,
    scan_hardware_host_uuid       uuid                        not null,
    scan_hardware_cpu_model       text                        not null, 
    scan_hardware_cpu_cores       numeric                     not null,     -- We don't care about individual sockets / chips
    scan_hardware_cpu_threads     numeric                     not null, 
    scan_hardware_cpu_bugs        text                        not null, 
    scan_hardware_cpu_flags       text                        not null,    --  
    scan_hardware_ram_total       numeric                     not null,    -- This is the sum of the hardware memory module capacity
    scan_hardware_memory_total    numeric                     not null,    -- This is the amount seen by the OS, minus shared memory, like that allocated to video
    scan_hardware_memory_free     numeric                     not null,    --  
    scan_hardware_swap_total      numeric                     not null,    --  
    scan_hardware_swap_free       numeric                     not null,    --  
    scan_hardware_led_id          text                        not null,    --  
    scan_hardware_led_css         text                        not null,    --  
    scan_hardware_led_error       text                        not null,    --  
    modified_date                 timestamp with time zone    not null,
    
    FOREIGN KEY(scan_hardware_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_hardware OWNER TO admin;

CREATE TABLE history.scan_hardware (
    history_id                    bigserial,
    scan_hardware_uuid            uuid,
    scan_hardware_host_uuid       uuid,
    scan_hardware_cpu_model       text, 
    scan_hardware_cpu_cores       numeric, 
    scan_hardware_cpu_threads     numeric, 
    scan_hardware_cpu_bugs        text, 
    scan_hardware_cpu_flags       text, 
    scan_hardware_ram_total       numeric,
    scan_hardware_memory_total    numeric, 
    scan_hardware_memory_free     numeric, 
    scan_hardware_swap_total      numeric, 
    scan_hardware_swap_free       numeric, 
    scan_hardware_led_id          text, 
    scan_hardware_led_css         text, 
    scan_hardware_led_error       text, 
    modified_date                 timestamp with time zone    not null
);
ALTER TABLE history.scan_hardware OWNER TO admin;

CREATE FUNCTION history_scan_hardware() RETURNS trigger
AS $$
DECLARE
    history_scan_hardware RECORD;
BEGIN
    SELECT INTO history_scan_hardware * FROM scan_hardware WHERE scan_hardware_uuid=new.scan_hardware_uuid;
    INSERT INTO history.scan_hardware
        (scan_hardware_uuid,
         scan_hardware_host_uuid, 
         scan_hardware_cpu_model, 
         scan_hardware_cpu_cores, 
         scan_hardware_cpu_threads, 
         scan_hardware_cpu_bugs, 
         scan_hardware_cpu_flags, 
         scan_hardware_ram_total, 
         scan_hardware_memory_total, 
         scan_hardware_memory_free, 
         scan_hardware_swap_total, 
         scan_hardware_swap_free, 
         scan_hardware_led_id, 
         scan_hardware_led_css, 
         scan_hardware_led_error, 
         modified_date)
    VALUES
        (history_scan_hardware.scan_hardware_uuid,
         history_scan_hardware.scan_hardware_host_uuid, 
         history_scan_hardware.scan_hardware_cpu_model, 
         history_scan_hardware.scan_hardware_cpu_cores, 
         history_scan_hardware.scan_hardware_cpu_threads, 
         history_scan_hardware.scan_hardware_cpu_bugs, 
         history_scan_hardware.scan_hardware_cpu_flags, 
         history_scan_hardware.scan_hardware_ram_total, 
         history_scan_hardware.scan_hardware_memory_total, 
         history_scan_hardware.scan_hardware_memory_free, 
         history_scan_hardware.scan_hardware_swap_total, 
         history_scan_hardware.scan_hardware_swap_free, 
         history_scan_hardware.scan_hardware_led_id, 
         history_scan_hardware.scan_hardware_led_css, 
         history_scan_hardware.scan_hardware_led_error, 
         history_scan_hardware.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_hardware() OWNER TO admin;

CREATE TRIGGER trigger_scan_hardware
    AFTER INSERT OR UPDATE ON scan_hardware
    FOR EACH ROW EXECUTE PROCEDURE history_scan_hardware();


CREATE TABLE scan_hardware_ram_modules (
    scan_hardware_ram_module_uuid             uuid                        primary key,
    scan_hardware_ram_module_host_uuid        uuid                        not null,
    scan_hardware_ram_module_locator          text                        not null, 
    scan_hardware_ram_module_size             numeric                     not null, 
    scan_hardware_ram_module_manufacturer     text                        not null, 
    scan_hardware_ram_module_model            text                        not null,
    scan_hardware_ram_module_serial_number    text                        not null,
    modified_date                             timestamp with time zone    not null,
    
    FOREIGN KEY(scan_hardware_ram_module_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_hardware_ram_modules OWNER TO admin;

CREATE TABLE history.scan_hardware_ram_modules (
    history_id                                bigserial,
    scan_hardware_ram_module_uuid             uuid,
    scan_hardware_ram_module_host_uuid        uuid,
    scan_hardware_ram_module_locator          text, 
    scan_hardware_ram_module_size             numeric, 
    scan_hardware_ram_module_manufacturer     text, 
    scan_hardware_ram_module_model            text, 
    scan_hardware_ram_module_serial_number    text, 
    modified_date                             timestamp with time zone    not null
);
ALTER TABLE history.scan_hardware_ram_modules OWNER TO admin;

CREATE FUNCTION history_scan_hardware_ram_modules() RETURNS trigger
AS $$
DECLARE
    history_scan_hardware_ram_modules RECORD;
BEGIN
    SELECT INTO history_scan_hardware_ram_modules * FROM scan_hardware_ram_modules WHERE scan_hardware_ram_module_uuid=new.scan_hardware_ram_module_uuid;
    INSERT INTO history.scan_hardware_ram_modules
        (scan_hardware_ram_module_uuid,
         scan_hardware_ram_module_host_uuid, 
         scan_hardware_ram_module_locator, 
         scan_hardware_ram_module_size, 
         scan_hardware_ram_module_manufacturer, 
         scan_hardware_ram_module_model, 
         scan_hardware_ram_module_serial_number, 
         modified_date)
    VALUES
        (history_scan_hardware_ram_modules.scan_hardware_ram_module_uuid,
         history_scan_hardware_ram_modules.scan_hardware_ram_module_host_uuid, 
         history_scan_hardware_ram_modules.scan_hardware_ram_module_locator, 
         history_scan_hardware_ram_modules.scan_hardware_ram_module_size, 
         history_scan_hardware_ram_modules.scan_hardware_ram_module_manufacturer, 
         history_scan_hardware_ram_modules.scan_hardware_ram_module_model, 
         history_scan_hardware_ram_modules.scan_hardware_ram_module_serial_number, 
         history_scan_hardware_ram_modules.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_hardware_ram_modules() OWNER TO admin;

CREATE TRIGGER trigger_scan_hardware_ram_modules
    AFTER INSERT OR UPDATE ON scan_hardware_ram_modules
    FOR EACH ROW EXECUTE PROCEDURE history_scan_hardware_ram_modules();
