# EC2インスタンスのパブリックIPなど、環境を構築した結果リソースに割り当てられた属性値を知りたい場合
# terraformコマンド実行時に指定した属性値がコンソール上に出力される
output "public_ip_of_cm-test" {
  value = aws_instance.cm-test.public_ip
}
