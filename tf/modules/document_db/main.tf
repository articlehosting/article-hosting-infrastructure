data "aws_availability_zones" "az_zones" {
}

resource "aws_security_group" "docdb_access" {
    name        = "hive-docdb-access-sg"
    description = "Allow access to DocumentDB"
    vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "docdb_access_ingress" {
    type                = "ingress"
    from_port           = "27017"
    to_port             = "27017"
    protocol            = "tcp"
    cidr_blocks         = concat(var.docdb_allowed_ip, split(" ", var.vpc_cidr))
    security_group_id   = aws_security_group.docdb_access.id
}

resource "aws_security_group_rule" "docdb_access_egress" {
    type                = "egress"
    from_port           = "0"
    to_port             = "0"
    protocol            = "-1"
    cidr_blocks         = ["0.0.0.0/0"]
    security_group_id   = aws_security_group.docdb_access.id
}

resource "aws_docdb_subnet_group" "docdb_subnets" {
    name        = "docdb_subnets"
    subnet_ids  = var.docdb_subnets
}

resource "aws_docdb_cluster" "articles_document_db_cluster" {
    cluster_identifier  = "hive-docdb-curie"
    engine_version      = "3.6.0"
    engine              = "docdb"
    port                = "27017"

    master_username     = var.docdb_username
    master_password     = var.docdb_password

    availability_zones      = data.aws_availability_zones.az_zones.names
    db_subnet_group_name    = aws_docdb_subnet_group.docdb_subnets.id
    vpc_security_group_ids  = [aws_security_group.docdb_access.id]

    deletion_protection = "true"
}

resource "aws_docdb_cluster_instance" "articles_docdb_instance" {
    count               = var.docdb_instance_count
    identifier          = "hive-docdb-curie-${count.index}"
    engine              = "docdb"
    instance_class      = "db.t3.medium"
    cluster_identifier  = aws_docdb_cluster.articles_document_db_cluster.id
}