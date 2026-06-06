# 🍕 Pizzaria DB — Banco de Dados para Pizzaria

Banco de dados relacional completo para gerenciamento de uma pizzaria, desenvolvido em **MySQL**. Inclui modelagem de pedidos, clientes, cardápio, entregas, estoque de bebidas e muito mais — com functions, views, procedures e triggers prontos para uso.

---

## 📦 Estrutura do Banco

### Tabelas

| Tabela | Descrição |
|---|---|
| `pizzaria` | Dados cadastrais da pizzaria (CNPJ, endereço, telefone) |
| `cliente` | Clientes cadastrados com endereço e data de cadastro |
| `pizza` | Cardápio de pizzas com sabor, tipo, tamanho, borda e preço |
| `ingrediente` | Ingredientes disponíveis com custo unitário |
| `pizza_ingrediente` | Relacionamento N:N entre pizzas e ingredientes |
| `bebida` | Bebidas com estoque, preço e data de atualização |
| `entrega` | Registros de entrega com taxa e tempo estimado |
| `pedido` | Pedidos realizados com forma de pagamento e valor total |
| `pedido_pizza` | Relacionamento N:N entre pedidos e pizzas |
| `pedido_bebida` | Relacionamento N:N entre pedidos e bebidas |

---

## 👁️ Views

| View | Descrição |
|---|---|
| `vw_consulta_simples` | Lista todas as pizzas com categoria calculada |
| `vw_clientes_cadastro_recente` | Clientes cadastrados nos últimos 365 dias |
| `vw_bebidas_atualizadas_mes` | Bebidas atualizadas no mês corrente |
| `vw_pizzas_nome_formatado` | Pizzas com formatações de texto (maiúsculo, extenso etc.) |
| `vw_clientes_formatados` | Clientes com nome em maiúsculo, localidade e telefone limpo |
| `vw_pedidos_completos` | Visão completa de pedidos com cliente, pizzaria e entrega |
| `vw_pizzas_com_ingredientes` | Pizzas com lista de ingredientes, custo e margem estimada |

---

## ⚙️ Functions

| Function | Descrição |
|---|---|
| `fn_ingredientes_pizza(id)` | Retorna sabor, ingredientes e custo total de uma pizza |
| `fn_resumo_pedido(id)` | Resumo completo de um pedido em texto |
| `fn_categoria_pizza(id)` | Classifica pizza em Econômica, Standard ou Premium |
| `fn_preco_pizza(id)` | Retorna sabor, preço e categoria de uma pizza |
| `fn_qtd_ingredientes(id)` | Retorna nome, quantidade e lista de ingredientes de uma pizza |
| `fn_formatar_telefone(tel)` | Formata telefone para padrão `(XX) XXXXX-XXXX` |

---

## 🔧 Procedures

| Procedure | Descrição |
|---|---|
| `sp_registrar_pedido` | Registra pedido completo e dá baixa no estoque automaticamente |
| `sp_relatorio_pedidos_periodo` | Relatório de pedidos entre duas datas |
| `sp_atualizar_bebida` | Atualiza preço e quantidade de uma bebida |
| `sp_inserir_pizza` | Cadastra nova pizza no cardápio |
| `sp_atualizar_preco_pizza` | Atualiza preço de uma pizza existente |
| `sp_baixar_estoque_bebidas` | Dá baixa no estoque de bebidas de pedidos pendentes |
| `sp_inserir_bebida` | Cadastra nova bebida no estoque |
| `sp_resumo_financeiro_cliente` | Retorna total de pedidos, valor acumulado e ticket médio de um cliente (OUT) |
| `sp_aplicar_desconto_pedido` | Aplica desconto percentual (máx. 30%) com economia calculada (INOUT/OUT) |
| `sp_gerar_pedidos_teste` | Gera 10 pedidos de teste automaticamente para validação |

---

## ⚡ Triggers

| Trigger | Evento | Descrição |
|---|---|---|
| `trg_atualizar_data_bebida` | BEFORE UPDATE (bebida) | Atualiza `data_atualizacao` ao alterar preço ou quantidade |
| `trg_bebida_estoque_negativo` | BEFORE UPDATE (bebida) | Impede estoque negativo |
| `trg_pizza_preco_invalido_insert` | BEFORE INSERT (pizza) | Impede preço ≤ 0 no cadastro |
| `trg_pizza_preco_invalido_update` | BEFORE UPDATE (pizza) | Impede preço ≤ 0 na atualização |
| `trg_bebida_preco_invalido_insert` | BEFORE INSERT (bebida) | Impede preço ≤ 0 no cadastro |
| `trg_bebida_preco_invalido_update` | BEFORE UPDATE (bebida) | Impede preço ≤ 0 na atualização |

---

## 🚀 Como usar

### 1. Importar o banco

```bash
mysql -u root -p < pizzaria_db.sql
```

### 2. Exemplos de uso

```sql
-- Registrar um pedido (cliente 1, entrega 1, pizza 1, bebida 1, PIX)
CALL sp_registrar_pedido(1, 1, 1, 1, 'PIX');

-- Relatório de pedidos de um período
CALL sp_relatorio_pedidos_periodo('2026-05-01', '2026-05-10');

-- Resumo financeiro de um cliente
CALL sp_resumo_financeiro_cliente(2, @qtd, @total, @ticket);
SELECT @qtd AS total_pedidos, @total AS valor_acumulado, @ticket AS ticket_medio;

-- Aplicar desconto em um pedido
SET @preco = 55.00;
CALL sp_aplicar_desconto_pedido(@preco, 15.00, @economia);
SELECT @preco AS preco_final, @economia AS economia_reais;

-- Verificar ingredientes de uma pizza
SELECT fn_ingredientes_pizza(2);

-- Consultar resumo de um pedido
SELECT fn_resumo_pedido(1);
```

---

## 📊 Dados de exemplo incluídos

- **1** pizzaria cadastrada
- **20** clientes
- **20** entregas
- **20** bebidas
- **24** pizzas com seus respectivos ingredientes
- **47** ingredientes
- **20** pedidos com pizzas e bebidas associadas

---

## 🛠️ Tecnologias

- **MySQL 8+** (compatível com `DEFAULT (CURRENT_DATE)` em colunas)
- Engine: **InnoDB** (suporte a transações e chaves estrangeiras)
- Charset: **utf8mb4** com collation **utf8mb4_unicode_ci**

---

## 📁 Arquivos

```
📦 pizzaria_db
 ┗ 📄 pizzaria_db.sql   # Script completo: DDL, DML, views, functions, procedures e triggers
```

---

## 📝 Licença

Projeto de estudo/demonstração. Livre para uso e adaptação. Feito por Kaick Ramos de Melo Silva
