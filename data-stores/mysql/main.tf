provider "aws" {
    region = "eu-west-1"
}

resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-up-and-running"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    skip_final_snapshot = true

    # enable backups
    backup_retention_period = var.backup_retention_period

    # if specified, this DB will be a replica
    replicate_source_db = var.replicate_source_db

    # only set these params if replicat_source_db is not set
    engine = var.replicate_source_db == null ? "mysql" : null
    db_name = var.replicate_source_db == null ? var.db_name : null
    username = var.replicate_source_db == null ? var.db_username : null
    password = var.replicate_source_db == null ? var.db_password : null

}

