-- Your SQL goes here
CREATE INDEX idx_parent ON domains(parent);
CREATE INDEX idx_field_id ON domains(field_id);
CREATE INDEX idx_target_address ON domains(target_address);
