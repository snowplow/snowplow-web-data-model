-- 11. APPEND MANIFEST

ALTER TABLE scratch.manifest APPEND FROM scratch.etl_tstamps; -- change to derived.manifest
