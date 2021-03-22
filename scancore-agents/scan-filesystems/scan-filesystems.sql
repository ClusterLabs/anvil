-- This is the database schema for the 'scan-lvm Scan Agent'.


-- This table stores physical volume information
CREATE TABLE scan_filesystems (
    scan_filesystem_uuid             uuid                        primary key,    -- This comes from the file system's UUID 
    scan_filesystem_host_uuid        uuid                        not null,       -- The host that the file system is mounted on. Note that some FSes, like those from USB, can move between hosts.
    scan_filesystem_type             text                        not null,       -- This is the name of the file system type.  
    scan_filesystem_kernel_name      text                        not null,       -- This is the backing device of the file system.
    scan_filesystem_mount_point      text                        not null,       -- This is the name of the mount point.  
    scan_filesystem_transport        text                        not null,       -- Optional description of the drive's transport (usb, nvme, sata, sata, md, raid, optical, sdcard, etc - 'unknown')
    scan_filesystem_media_type       text                        not null,       -- This is set to 'ssd' for solid state, 'platter' for spinning rust, 'network' for network mounts, etc.
    scan_filesystem_vendor           text                        not null,       -- Optional vendor of the drive the partition is on
    scan_filesystem_model            text                        not null,       -- Optional model of the drive the partiton is on
    scan_filesystem_serial_number    text                        not null,       -- Optional serial number of the drive the partition is on
    scan_filesystem_description      text                        not null,       -- Free form description of the device.
    scan_filesystem_size             numeric                     not null,       -- The size of the partition, in bytes
    scan_filesystem_used             numeric                     not null,       -- The used space, in bytes.
    modified_date                    timestamp with time zone    not null,
    
    FOREIGN KEY(scan_filesystem_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_filesystems OWNER TO admin;

CREATE TABLE history.scan_filesystems (
    history_id                       bigserial,
    scan_filesystem_uuid             uuid,
    scan_filesystem_host_uuid        uuid,
    scan_filesystem_type             text,
    scan_filesystem_kernel_name      text,
    scan_filesystem_mount_point      text,
    scan_filesystem_transport        text,
    scan_filesystem_media_type       text,
    scan_filesystem_vendor           text, 
    scan_filesystem_model            text, 
    scan_filesystem_serial_number    text, 
    scan_filesystem_description      text,
    scan_filesystem_size             numeric,
    scan_filesystem_used             numeric,
    modified_date                    timestamp with time zone    not null
);
ALTER TABLE history.scan_filesystems OWNER TO admin;

CREATE FUNCTION history_scan_filesystems() RETURNS trigger
AS $$
DECLARE
    history_scan_filesystems RECORD;
BEGIN
    SELECT INTO history_scan_filesystems * FROM scan_filesystems WHERE scan_filesystem_uuid=new.scan_filesystem_uuid;
    INSERT INTO history.scan_filesystems
        (scan_filesystem_uuid,
         scan_filesystem_host_uuid, 
         scan_filesystem_type, 
         scan_filesystem_kernel_name, 
         scan_filesystem_mount_point, 
         scan_filesystem_transport, 
         scan_filesystem_media_type, 
         scan_filesystem_vendor, 
         scan_filesystem_model, 
         scan_filesystem_serial_number, 
         scan_filesystem_description, 
         scan_filesystem_size, 
         scan_filesystem_used, 
         modified_date)
    VALUES
        (history_scan_filesystems.scan_filesystem_uuid,
         history_scan_filesystems.scan_filesystem_host_uuid, 
         history_scan_filesystems.scan_filesystem_type, 
         history_scan_filesystems.scan_filesystem_kernel_name, 
         history_scan_filesystems.scan_filesystem_mount_point, 
         history_scan_filesystems.scan_filesystem_transport, 
         history_scan_filesystems.scan_filesystem_media_type, 
         history_scan_filesystems.scan_filesystem_vendor, 
         history_scan_filesystems.scan_filesystem_model, 
         history_scan_filesystems.scan_filesystem_serial_number, 
         history_scan_filesystems.scan_filesystem_description, 
         history_scan_filesystems.scan_filesystem_size, 
	 history_scan_filesystems.scan_filesystem_used, 
         history_scan_filesystems.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_filesystems() OWNER TO admin;

CREATE TRIGGER trigger_scan_filesystems
    AFTER INSERT OR UPDATE ON scan_filesystems
    FOR EACH ROW EXECUTE PROCEDURE history_scan_filesystems();
