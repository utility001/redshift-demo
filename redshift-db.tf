# REDSHIFT SUBNET GROUP
resource "aws_redshift_subnet_group" "subnet_group" {
  name       = "rdshift-subnet-group"
  subnet_ids = [aws_subnet.private_sub.id]
}

# REDSHFIT CLUSTER
resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier = "sj-redshift-cluster" # Name of the cluster
  cluster_type       = "multi-node"

  database_name = "mydb"

  node_type       = "dc2.large" # 15gb ram, 2 default node slices, etc
  number_of_nodes = 3

  master_username        = "admin"
  manage_master_password = true # Whether to use SecretsManager to manage the admin credential

  vpc_security_group_ids    = [aws_security_group.redshift_sg.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.subnet_group.name
}