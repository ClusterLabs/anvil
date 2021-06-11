-- This is the database schema for the 'scan-lvm Scan Agent'.


-- This table stores physical volume information
CREATE TABLE scan_lvm_pvs (
    scan_lvm_pv_uuid             uuid                        primary key,    
    scan_lvm_pv_host_uuid        uuid                        not null,
    scan_lvm_pv_internal_uuid    text                        not null,       -- This comes from the PV itself. This is not a valid UUID format, so we use it more as a "serial number"
    scan_lvm_pv_name             text                        not null,       -- This is the name of the PV.  
    scan_lvm_pv_used_by_vg       text                        not null,       -- This is the name of the VG that uses this PV. If it's blank, then no VG uses it yet.  
    scan_lvm_pv_attributes       text                        not null,       -- This is the short 3-character attribute of the PV
    scan_lvm_pv_size             numeric                     not null,       -- The size of the PV in bytes
    scan_lvm_pv_free             numeric                     not null,       -- The free space, in bytes.
    scan_lvm_pv_sector_size      numeric                     not null,       -- This is the size of the sectors on this disk. Genreally it is 512 or 4096. This is important for calculating how much space to add to LVs built on this PV.
    modified_date                timestamp with time zone    not null,
    
    FOREIGN KEY(scan_lvm_pv_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_lvm_pvs OWNER TO admin;

CREATE TABLE history.scan_lvm_pvs (
    history_id                   bigserial,
    scan_lvm_pv_uuid             uuid,
    scan_lvm_pv_host_uuid        uuid,
    scan_lvm_pv_internal_uuid    text,
    scan_lvm_pv_name             text,
    scan_lvm_pv_used_by_vg       text,
    scan_lvm_pv_attributes       text,
    scan_lvm_pv_size             numeric,
    scan_lvm_pv_free             numeric,
    scan_lvm_pv_sector_size      numeric,
    modified_date                timestamp with time zone    not null
);
ALTER TABLE history.scan_lvm_pvs OWNER TO admin;

CREATE FUNCTION history_scan_lvm_pvs() RETURNS trigger
AS $$
DECLARE
    history_scan_lvm_pvs RECORD;
BEGIN
    SELECT INTO history_scan_lvm_pvs * FROM scan_lvm_pvs WHERE scan_lvm_pv_uuid=new.scan_lvm_pv_uuid;
    INSERT INTO history.scan_lvm_pvs
        (scan_lvm_pv_uuid,
         scan_lvm_pv_host_uuid, 
         scan_lvm_pv_internal_uuid, 
         scan_lvm_pv_name, 
         scan_lvm_pv_used_by_vg, 
         scan_lvm_pv_attributes, 
         scan_lvm_pv_size, 
         scan_lvm_pv_free, 
         scan_lvm_pv_sector_size, 
         modified_date)
    VALUES
        (history_scan_lvm_pvs.scan_lvm_pv_uuid,
         history_scan_lvm_pvs.scan_lvm_pv_host_uuid, 
         history_scan_lvm_pvs.scan_lvm_pv_internal_uuid, 
         history_scan_lvm_pvs.scan_lvm_pv_name, 
         history_scan_lvm_pvs.scan_lvm_pv_used_by_vg, 
         history_scan_lvm_pvs.scan_lvm_pv_attributes, 
         history_scan_lvm_pvs.scan_lvm_pv_size, 
	 history_scan_lvm_pvs.scan_lvm_pv_free, 
	 history_scan_lvm_pvs.scan_lvm_pv_sector_size, 
         history_scan_lvm_pvs.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_lvm_pvs() OWNER TO admin;

CREATE TRIGGER trigger_scan_lvm_pvs
    AFTER INSERT OR UPDATE ON scan_lvm_pvs
    FOR EACH ROW EXECUTE PROCEDURE history_scan_lvm_pvs();


-- This table stores volume group information
CREATE TABLE scan_lvm_vgs (
    scan_lvm_vg_uuid             uuid                        primary key,
    scan_lvm_vg_host_uuid        uuid                        not null,
    scan_lvm_vg_internal_uuid    text                        not null,       -- This comes from the VG itself. This is not a valid UUID format, so we use it more as a "serial number"
    scan_lvm_vg_name             text                        not null,       -- This is the name of the VG.  
    scan_lvm_vg_attributes       text                        not null,       -- This is the short 6-character attribute of the VG
    scan_lvm_vg_extent_size      numeric                     not null,       -- The size of each physical extent, in bytes.
    scan_lvm_vg_size             numeric                     not null,       -- The size of the VG, in bytes.
    scan_lvm_vg_free             numeric                     not null,       -- The free space in the VG, in bytes.
    modified_date                timestamp with time zone    not null,
    
    FOREIGN KEY(scan_lvm_vg_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_lvm_vgs OWNER TO admin;

CREATE TABLE history.scan_lvm_vgs (
    history_id                   bigserial,
    scan_lvm_vg_uuid             uuid,
    scan_lvm_vg_host_uuid        uuid,
    scan_lvm_vg_internal_uuid    text,
    scan_lvm_vg_name             text,
    scan_lvm_vg_attributes       text,
    scan_lvm_vg_extent_size      numeric,
    scan_lvm_vg_size             numeric,
    scan_lvm_vg_free             numeric,
    modified_date                timestamp with time zone    not null
);
ALTER TABLE history.scan_lvm_vgs OWNER TO admin;

CREATE FUNCTION history_scan_lvm_vgs() RETURNS trigger
AS $$
DECLARE
    history_scan_lvm_vgs RECORD;
BEGIN
    SELECT INTO history_scan_lvm_vgs * FROM scan_lvm_vgs WHERE scan_lvm_vg_uuid=new.scan_lvm_vg_uuid;
    INSERT INTO history.scan_lvm_vgs
        (scan_lvm_vg_uuid,
         scan_lvm_vg_host_uuid, 
         scan_lvm_vg_internal_uuid, 
         scan_lvm_vg_name, 
         scan_lvm_vg_attributes,
         scan_lvm_vg_extent_size,
         scan_lvm_vg_size,
         scan_lvm_vg_free,
         modified_date)
    VALUES
        (history_scan_lvm_vgs.scan_lvm_vg_uuid,
         history_scan_lvm_vgs.scan_lvm_vg_host_uuid, 
         history_scan_lvm_vgs.scan_lvm_vg_internal_uuid, 
         history_scan_lvm_vgs.scan_lvm_vg_name, 
         history_scan_lvm_vgs.scan_lvm_vg_attributes,
         history_scan_lvm_vgs.scan_lvm_vg_extent_size,
         history_scan_lvm_vgs.scan_lvm_vg_size,
         history_scan_lvm_vgs.scan_lvm_vg_free,
         history_scan_lvm_vgs.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_lvm_vgs() OWNER TO admin;

CREATE TRIGGER trigger_scan_lvm_vgs
    AFTER INSERT OR UPDATE ON scan_lvm_vgs
    FOR EACH ROW EXECUTE PROCEDURE history_scan_lvm_vgs();


--lvs - lv_name,lv_uuid,lv_attr,vg_name,lv_size,lv_path,devices
CREATE TABLE scan_lvm_lvs (
    scan_lvm_lv_uuid             uuid                        primary key,
    scan_lvm_lv_host_uuid        uuid                        not null,
    scan_lvm_lv_internal_uuid    text                        not null,       -- This comes from the LV itself. This is not a valid UUID format, so we use it more as a "serial number"
    scan_lvm_lv_name             text                        not null,       -- This is the name of the VG.  
    scan_lvm_lv_attributes       text                        not null,       -- This is the short 9-character attribute of the LV
    scan_lvm_lv_on_vg            text                        not null,       -- This is the name of the volume group this LV is on
    scan_lvm_lv_size             numeric                     not null,       -- The size of the VG, in bytes.
    scan_lvm_lv_path             text                        not null,       -- The device path to this LV
    scan_lvm_lv_on_pvs           text                        not null,       -- This is a comma-separated list of PVs this LV spans over.
    modified_date                timestamp with time zone    not null,
    
    FOREIGN KEY(scan_lvm_lv_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_lvm_lvs OWNER TO admin;

CREATE TABLE history.scan_lvm_lvs (
    history_id                   bigserial,
    scan_lvm_lv_uuid             uuid,
    scan_lvm_lv_host_uuid        uuid,
    scan_lvm_lv_internal_uuid    text, 
    scan_lvm_lv_name             text,
    scan_lvm_lv_attributes       text,
    scan_lvm_lv_on_vg            text,
    scan_lvm_lv_size             numeric,
    scan_lvm_lv_path             text,
    scan_lvm_lv_on_pvs           text,
    modified_date                timestamp with time zone    not null
);
ALTER TABLE history.scan_lvm_lvs OWNER TO admin;

CREATE FUNCTION history_scan_lvm_lvs() RETURNS trigger
AS $$
DECLARE
    history_scan_lvm_lvs RECORD;
BEGIN
    SELECT INTO history_scan_lvm_lvs * FROM scan_lvm_lvs WHERE scan_lvm_lv_uuid=new.scan_lvm_lv_uuid;
    INSERT INTO history.scan_lvm_lvs
        (scan_lvm_lv_uuid,
         scan_lvm_lv_host_uuid, 
         scan_lvm_lv_internal_uuid, 
         scan_lvm_lv_name, 
         scan_lvm_lv_attributes,
         scan_lvm_lv_on_vg,
         scan_lvm_lv_size,
         scan_lvm_lv_path,
         scan_lvm_lv_on_pvs,
         modified_date)
    VALUES
        (history_scan_lvm_lvs.scan_lvm_lv_uuid,
         history_scan_lvm_lvs.scan_lvm_lv_host_uuid, 
         history_scan_lvm_lvs.scan_lvm_lv_internal_uuid, 
         history_scan_lvm_lvs.scan_lvm_lv_name, 
         history_scan_lvm_lvs.scan_lvm_lv_attributes,
         history_scan_lvm_lvs.scan_lvm_lv_on_vg,
         history_scan_lvm_lvs.scan_lvm_lv_size,
         history_scan_lvm_lvs.scan_lvm_lv_path,
         history_scan_lvm_lvs.scan_lvm_lv_on_pvs,
         history_scan_lvm_lvs.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_lvm_lvs() OWNER TO admin;

CREATE TRIGGER trigger_scan_lvm_lvs
    AFTER INSERT OR UPDATE ON scan_lvm_lvs
    FOR EACH ROW EXECUTE PROCEDURE history_scan_lvm_lvs();
