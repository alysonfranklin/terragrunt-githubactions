# GitHub Actions Workflow: Terraform Deployment

Este repositório contém um workflow do GitHub Actions para gerenciar implantações do Terraform em várias contas AWS. O workflow permite aplicar ou destruir a infraestrutura de acordo com os inputs fornecidos pelo usuário.

## Nome do Workflow

`Terraform - Multiple AWS Accounts`

## Como Utilizar

### Despachando o Workflow Manualmente

Você pode disparar este workflow manualmente pelo GitHub Actions, fornecendo os seguintes inputs:

- **action**: Ação a ser realizada (`apply` ou `destroy`). Padrão: `apply`.
- **aws_account**: Conta AWS onde a infraestrutura será implantada (`data`, `prod`, `stage`, `hml`).
- **terraform_directory**: Diretório contendo o código Terraform.
- **terraform_version**: Versão do Terraform a ser utilizada. Padrão: `1.0.0`.

### Exemplo de Despacho Manual

1. Vá para a aba "Actions" no seu repositório GitHub.
2. Selecione o workflow `Testing`.
3. Clique em "Run workflow".
4. Preencha os inputs necessários e clique em "Run workflow".

## Funcionalidade do Workflow

### 1. Plano

- **Configura Credenciais AWS**: Configura as credenciais AWS com base na conta especificada (`data`, `prod`, `stage`, `hml`).
- **Checkout do Código**: Faz checkout do repositório.
- **Setup do Terraform**: Configura a versão do Terraform especificada.
- **Setup do Terragrunt**: Instala e configura o Terragrunt.
- **Plano de Mudanças do Terraform**: Executa `terragrunt plan` ou `terragrunt plan -destroy` com base na ação especificada.
- **Upload de Artifacts**: Faz upload dos arquivos do repositório e do binário do Terragrunt como artifacts.

### 2. Aprovação

- **Notificação no Slack**: Envia uma notificação no Slack informando que a implantação está pendente de aprovação.
- **Aprovação Manual**: Aguarda a aprovação manual para continuar com a implantação.

### 3. Deploy

- **Configura Credenciais AWS**: Configura as credenciais AWS com base na conta especificada (`data`, `prod`, `stage`, `hml`).
- **Download de Artifacts**: Faz download dos artifacts do repositório e do binário do Terragrunt.
- **Setup do Terragrunt**: Configura o Terragrunt.
- **Aplicar ou Destruir Infraestrutura**: Executa `terragrunt apply` ou `terragrunt destroy` com base na ação especificada.

### 4. Notificação

- **Determina o Status da Implantação**: Verifica o status da implantação (sucesso, falha ou cancelamento).
- **Notificação no Slack**: Envia uma notificação no Slack com o status da implantação.

## Configuração de Segredos

Para que este workflow funcione corretamente, você deve configurar os seguintes segredos no seu repositório GitHub:

- `AWS_ROLE_ARN_DATA`
- `AWS_ROLE_ARN_PROD`
- `AWS_ROLE_ARN_STAGE`
- `AWS_ROLE_ARN_HML`
- `SLACK_WEBHOOK_URL`

## Exemplos de Inputs

### Exemplo 1: Aplicar Infraestrutura em Produção

```yaml
action: apply
aws_account: prod
terraform_directory: infra/prod
terraform_version: 1.0.0
```

### Exemplo 2: Destruir Infraestrutura em Ambiente de Homologação
```yaml
action: destroy
aws_account: hml
terraform_directory: infra/hml
terraform_version: 1.0.0
``` 

# Autenticação via OIDC com AWS e GitHub Actions

Aqui demonstro como configurar a autenticação via OIDC (OpenID Connect) entre GitHub Actions e AWS para permitir que os workflows do GitHub Actions assumam funções no AWS IAM usando tokens OIDC.

## Passos para Configuração

### 1. Criar um Provedor de Identidade OIDC no AWS

1. Acesse o Console de Gerenciamento do AWS e abra o serviço IAM.
2. No painel de navegação, clique em "Provedores de identidade".
3. Clique em "Adicionar provedor de identidade".
4. Selecione "OpenID Connect" como o tipo de provedor.
5. Insira a URL do emissor: `https://token.actions.githubusercontent.com`.
6. Insira `sts.amazonaws.com` como o público (audience).
7. Clique em "Adicionar provedor de identidade".

### 2. Criar uma Função IAM com Confiança no Provedor OIDC

1. No Console IAM, vá para "Funções" e clique em "Criar função".
2. Selecione "Outra conta da AWS".
3. Em "Relações de confiança", adicione o seguinte documento de política de confiança:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>:ref:refs/heads/<YOUR_BRANCH_NAME>"
        }
      }
    }
  ]
}
```

- Substitua <`YOUR_AWS_ACCOUNT_ID`>, <`YOUR_GITHUB_USERNAME/ORGANIZATION`>, <`YOUR_REPO_NAME`> e <`YOUR_BRANCH_NAME`> pelos valores apropriados.

4. Clique em "Avançar: Permissões".
5. Selecione as políticas necessárias para a função (ex.: AmazonS3FullAccess).
6. Clique em "Avançar: Tags" e depois em "Avançar: Revisar".
7. Dê um nome à função e clique em "Criar função".

## Contribuindo
Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests com melhorias e correções.

## Licença
Este projeto está licenciado sob a MIT License.

Este `README.md` fornece instruções detalhadas sobre como usar o workflow, explica sua funcionalidade, descreve como configurar os segredos necessários e inclui exemplos de uso.

