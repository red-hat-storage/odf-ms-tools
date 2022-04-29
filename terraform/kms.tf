resource "aws_kms_key" "odf" {
  description = "ODF Managed Service"
  key_usage   = "SIGN_VERIFY"
  customer_master_key_spec = "RSA_4096"
}  

resource "aws_kms_alias" "odf_alias" {
  name = "alias/odf"
  target_key_id = aws_kms_key.odf.key_id
}
