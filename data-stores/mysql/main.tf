resource "aws_db_instance" "my_db" {
    identifier_prefix = "terraform-up-and-running"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    skip_final_snapshot = true
    db_name = var.db_name

    # How should we set our password?
    username = var.db_username
    password = var.db_password
  
}