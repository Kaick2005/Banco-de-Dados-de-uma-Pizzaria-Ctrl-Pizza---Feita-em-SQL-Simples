DROP DATABASE IF EXISTS pizzaria_db;
CREATE DATABASE pizzaria_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE pizzaria_db;
 
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS pedido_bebida;
DROP TABLE IF EXISTS pedido_pizza;
DROP TABLE IF EXISTS pizza_ingrediente;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS entrega;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS pizzaria;
DROP TABLE IF EXISTS ingrediente;
DROP TABLE IF EXISTS pizza;
DROP TABLE IF EXISTS bebida;
DROP VIEW IF EXISTS vw_consulta_simples;
DROP VIEW IF EXISTS vw_clientes_cadastro_recente;
DROP VIEW IF EXISTS vw_bebidas_atualizadas_mes;
DROP VIEW IF EXISTS vw_pizzas_nome_formatado;
DROP VIEW IF EXISTS vw_clientes_formatados;
DROP VIEW IF EXISTS vw_pedidos_completos;
DROP VIEW IF EXISTS vw_pizzas_com_ingredientes;
DROP FUNCTION IF EXISTS fn_ingredientes_pizza;
DROP FUNCTION IF EXISTS fn_resumo_pedido;
DROP FUNCTION IF EXISTS fn_fator_tamanho;
DROP FUNCTION IF EXISTS fn_preco_final;
DROP FUNCTION IF EXISTS fn_total_pedido;
DROP FUNCTION IF EXISTS fn_desconto_pizza;
DROP FUNCTION IF EXISTS fn_categoria_pizza;
DROP FUNCTION IF EXISTS fn_preco_pizza;
DROP FUNCTION IF EXISTS fn_qtd_ingredientes;
DROP FUNCTION IF EXISTS fn_formatar_telefone;
SET FOREIGN_KEY_CHECKS = 1;
 
CREATE TABLE pizzaria (
  cnpj CHAR(14) NOT NULL,
  nome VARCHAR(120) NOT NULL,
  telefone VARCHAR(20) NOT NULL,
  rua VARCHAR(120) NOT NULL,
  numero VARCHAR(10) NOT NULL,
  complemento VARCHAR(80) NULL,
  bairro VARCHAR(80) NOT NULL,
  cidade VARCHAR(80) NOT NULL,
  estado CHAR(2) NOT NULL,
  cep CHAR(8) NOT NULL,
  PRIMARY KEY (cnpj)
) ENGINE=InnoDB;
 
CREATE TABLE cliente (
  id_cliente INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  telefone VARCHAR(20) NOT NULL,
  rua VARCHAR(120) NOT NULL,
  numero VARCHAR(10) NOT NULL,
  complemento VARCHAR(80) NULL,
  bairro VARCHAR(80) NOT NULL,
  cidade VARCHAR(80) NOT NULL,
  estado CHAR(2) NOT NULL,
  cep CHAR(8) NOT NULL,
  data_cadastro DATE NOT NULL DEFAULT (CURRENT_DATE),
  PRIMARY KEY (id_cliente)
) ENGINE=InnoDB;
 
CREATE TABLE entrega (
  codigo_entrega INT NOT NULL AUTO_INCREMENT,
  cnpj_pizzaria CHAR(14) NOT NULL,
  tempo_estimado INT NOT NULL,
  endereco_entrega VARCHAR(255) NOT NULL,
  taxa DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (codigo_entrega),
  CONSTRAINT fk_entrega_pizzaria
    FOREIGN KEY (cnpj_pizzaria) REFERENCES pizzaria (cnpj)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;
 
CREATE TABLE bebida (
  id_bebida INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  quantidade INT NOT NULL DEFAULT 1,
  preco DECIMAL(10,2) NOT NULL,
  data_atualizacao DATE NOT NULL DEFAULT (CURRENT_DATE),
  PRIMARY KEY (id_bebida)
) ENGINE=InnoDB;
 
CREATE TABLE pizza (
  id_pizza INT NOT NULL AUTO_INCREMENT,
  sabor VARCHAR(120) NOT NULL,
  tipo ENUM('TRADICIONAL','ESPECIAL') NOT NULL,
  tamanho ENUM('P','M','G') NOT NULL,
  borda VARCHAR(80) NULL,
  quantidade INT NOT NULL DEFAULT 1,
  preco DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_pizza)
) ENGINE=InnoDB;
 
CREATE TABLE ingrediente (
  codigo INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  preco DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (codigo)
) ENGINE=InnoDB;
 
CREATE TABLE pedido (
  id_pedido INT NOT NULL AUTO_INCREMENT,
  cnpj_pizzaria CHAR(14) NOT NULL,
  id_cliente INT NOT NULL,
  codigo_entrega INT NULL,
  forma_pagamento ENUM('PIX','DINHEIRO','CARTAO') NOT NULL,
  valor_total DECIMAL(10,2) NOT NULL,
  data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_pedido),
  CONSTRAINT fk_pedido_pizzaria
    FOREIGN KEY (cnpj_pizzaria) REFERENCES pizzaria (cnpj)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_cliente
    FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_entrega
    FOREIGN KEY (codigo_entrega) REFERENCES entrega (codigo_entrega)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;
 
CREATE TABLE pedido_pizza (
  id_pedido INT NOT NULL,
  id_pizza INT NOT NULL,
  PRIMARY KEY (id_pedido, id_pizza),
  CONSTRAINT fk_pp_pedido FOREIGN KEY (id_pedido) REFERENCES pedido (id_pedido)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pp_pizza FOREIGN KEY (id_pizza) REFERENCES pizza (id_pizza)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;
 
CREATE TABLE pedido_bebida (
  id_pedido INT NOT NULL,
  id_bebida INT NOT NULL,
  PRIMARY KEY (id_pedido, id_bebida),
  CONSTRAINT fk_pb_pedido FOREIGN KEY (id_pedido) REFERENCES pedido (id_pedido)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pb_bebida FOREIGN KEY (id_bebida) REFERENCES bebida (id_bebida)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;
 
CREATE TABLE pizza_ingrediente (
  id_pizza INT NOT NULL,
  codigo_ingrediente INT NOT NULL,
  PRIMARY KEY (id_pizza, codigo_ingrediente),
  CONSTRAINT fk_pi_pizza FOREIGN KEY (id_pizza) REFERENCES pizza (id_pizza)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pi_ingrediente FOREIGN KEY (codigo_ingrediente) REFERENCES ingrediente (codigo)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;
 
DELIMITER $$
 
CREATE FUNCTION fn_ingredientes_pizza(p_id_pizza INT)
RETURNS TEXT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_sabor VARCHAR(120);
  DECLARE v_lista TEXT;
  DECLARE v_total DECIMAL(10,2);
  SELECT sabor INTO v_sabor FROM pizza WHERE id_pizza = p_id_pizza;
  SELECT GROUP_CONCAT(i.nome, ' R$', FORMAT(i.preco, 2) ORDER BY i.nome SEPARATOR ', ')
    INTO v_lista
    FROM pizza_ingrediente pi
    INNER JOIN ingrediente i ON pi.codigo_ingrediente = i.codigo
    WHERE pi.id_pizza = p_id_pizza;
  SELECT ROUND(SUM(i.preco), 2)
    INTO v_total
    FROM pizza_ingrediente pi
    INNER JOIN ingrediente i ON pi.codigo_ingrediente = i.codigo
    WHERE pi.id_pizza = p_id_pizza;
  RETURN CONCAT('Pizza: ', v_sabor, ' | ', v_lista, ' | Total: R$', FORMAT(v_total, 2));
END$$
 
CREATE FUNCTION fn_resumo_pedido(p_id_pedido INT)
RETURNS TEXT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_cliente VARCHAR(120);
  DECLARE v_pizzaria VARCHAR(120);
  DECLARE v_pizzas TEXT;
  DECLARE v_bebidas TEXT;
  DECLARE v_pagamento VARCHAR(10);
  DECLARE v_total DECIMAL(10,2);
  DECLARE v_data VARCHAR(20);
  SELECT c.nome, pz.nome, p.forma_pagamento, p.valor_total,
         DATE_FORMAT(p.data_pedido, '%d/%m/%Y %H:%i')
    INTO v_cliente, v_pizzaria, v_pagamento, v_total, v_data
    FROM pedido p
    INNER JOIN cliente c ON p.id_cliente = c.id_cliente
    INNER JOIN pizzaria pz ON p.cnpj_pizzaria = pz.cnpj
    WHERE p.id_pedido = p_id_pedido;
  SELECT GROUP_CONCAT(pz.sabor ORDER BY pz.sabor SEPARATOR ', ')
    INTO v_pizzas
    FROM pedido_pizza pp
    INNER JOIN pizza pz ON pp.id_pizza = pz.id_pizza
    WHERE pp.id_pedido = p_id_pedido;
  SELECT GROUP_CONCAT(b.nome ORDER BY b.nome SEPARATOR ', ')
    INTO v_bebidas
    FROM pedido_bebida pb
    INNER JOIN bebida b ON pb.id_bebida = b.id_bebida
    WHERE pb.id_pedido = p_id_pedido;
  RETURN CONCAT(
    'Pedido #', p_id_pedido,
    ' | Data: ', v_data,
    ' | Cliente: ', v_cliente,
    ' | Pizzaria: ', v_pizzaria,
    ' | Pizza(s): ', IFNULL(v_pizzas, 'Nenhuma'),
    ' | Bebida(s): ', IFNULL(v_bebidas, 'Nenhuma'),
    ' | Pagamento: ', v_pagamento,
    ' | Total: R$', FORMAT(v_total, 2)
  );
END$$
 
CREATE FUNCTION fn_categoria_pizza(p_id_pizza INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_preco DECIMAL(10,2);
  SELECT preco INTO v_preco FROM pizza WHERE id_pizza = p_id_pizza;
  RETURN CASE
    WHEN v_preco <= 30.00 THEN 'Econômica'
    WHEN v_preco <= 45.00 THEN 'Standard'
    ELSE 'Premium'
  END;
END$$
 
CREATE FUNCTION fn_preco_pizza(p_id_pizza INT)
RETURNS TEXT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_sabor VARCHAR(120);
  DECLARE v_preco DECIMAL(10,2);
  DECLARE v_categoria VARCHAR(20);
  SELECT sabor, preco INTO v_sabor, v_preco
    FROM pizza WHERE id_pizza = p_id_pizza LIMIT 1;
  SET v_categoria = CASE
    WHEN v_preco <= 30.00 THEN 'Econômica'
    WHEN v_preco <= 45.00 THEN 'Standard'
    ELSE 'Premium'
  END;
  RETURN CONCAT(
    'Pizza: ', IFNULL(v_sabor, 'Não encontrada'),
    ' | Preço: R$', FORMAT(IFNULL(v_preco, 0), 2),
    ' | Categoria: ', v_categoria
  );
END$$
 
CREATE FUNCTION fn_qtd_ingredientes(p_id_pizza INT)
RETURNS TEXT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_sabor VARCHAR(120);
  DECLARE v_quantidade INT;
  DECLARE v_lista TEXT;
  SELECT sabor INTO v_sabor FROM pizza WHERE id_pizza = p_id_pizza LIMIT 1;
  SELECT COUNT(*) INTO v_quantidade FROM pizza_ingrediente WHERE id_pizza = p_id_pizza;
  SELECT GROUP_CONCAT(i.nome ORDER BY i.nome SEPARATOR ', ')
    INTO v_lista
    FROM pizza_ingrediente pi
    INNER JOIN ingrediente i ON pi.codigo_ingrediente = i.codigo
    WHERE pi.id_pizza = p_id_pizza;
  RETURN CONCAT(
    'Pizza: ', IFNULL(v_sabor, 'Não encontrada'),
    ' | Qtd. ingredientes: ', v_quantidade,
    ' | Ingredientes: ', IFNULL(v_lista, 'Nenhum')
  );
END$$
 
CREATE FUNCTION fn_formatar_telefone(p_telefone VARCHAR(20))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
  DECLARE v_limpo VARCHAR(20);
  SET v_limpo = REPLACE(REPLACE(REPLACE(REPLACE(p_telefone, '(', ''), ')', ''), '-', ''), ' ', '');
  IF LENGTH(v_limpo) = 11 THEN
    RETURN CONCAT('(', SUBSTRING(v_limpo,1,2), ') ', SUBSTRING(v_limpo,3,5), '-', SUBSTRING(v_limpo,8,4));
  ELSEIF LENGTH(v_limpo) = 10 THEN
    RETURN CONCAT('(', SUBSTRING(v_limpo,1,2), ') ', SUBSTRING(v_limpo,3,4), '-', SUBSTRING(v_limpo,7,4));
  ELSE
    RETURN p_telefone;
  END IF;
END$$
 
DELIMITER ;
 
INSERT INTO pizzaria (cnpj, nome, telefone, rua, numero, complemento, bairro, cidade, estado, cep) VALUES
('28456123000190','Ctrl-Pizzaria','81981234567','R. João Fernandes Viêira','1200','Loja 1','Matriz','Vitória de Santo Antão','PE','55612350');
 
ALTER TABLE cliente AUTO_INCREMENT = 1;
 
INSERT INTO cliente (nome, telefone, rua, numero, complemento, bairro, cidade, estado, cep, data_cadastro) VALUES
('Ana Cristina','81970001111','Rua das Flores','10',NULL,'Santo Amaro','Recife','PE','50100000','2024-01-10'),
('Maria Souza','81970002222','Av Boa Viagem','500','Apto 302','Boa Viagem','Recife','PE','51011000','2024-03-15'),
('Carlos Lima','81970003333','Rua do Pina','33',NULL,'Pina','Recife','PE','51110000','2024-06-20'),
('João Silva','81970004444','Av Boa Viagem','900','Apto 101','Boa Viagem','Recife','PE','51011000','2025-01-05'),
('Bruno Rocha','81970005555','Rua do Centro','5',NULL,'Centro','Recife','PE','50010000','2025-02-18'),
('Fernanda Alves','81970006666','Av Boa Viagem','1200',NULL,'Boa Viagem','Recife','PE','51011000','2025-03-22'),
('Rafael Costa','81970007777','Rua das Graças','77',NULL,'Graças','Recife','PE','52050000','2025-08-10'),
('Juliana Melo','81970008888','Av Boa Viagem','1800','Cobertura','Boa Viagem','Recife','PE','51011000','2025-11-30'),
('Thiago Ramos','81970009999','Rua Nova','99',NULL,'Boa Viagem','Recife','PE','51020000','2026-01-14'),
('Patrícia Gomes','81970010000','Rua da Madalena','200',NULL,'Madalena','Recife','PE','50610000','2026-04-02'),
('Lucas Ferreira','81970011111','Rua do Futuro','15',NULL,'Espinheiro','Recife','PE','52020000','2026-04-10'),
('Isabela Nunes','81970012222','Av Domingos Ferreira','430','Apto 201','Boa Viagem','Recife','PE','51020000','2026-04-12'),
('Rodrigo Carvalho','81970013333','Rua Henrique Dias','88',NULL,'Santo Amaro','Recife','PE','50100100','2026-04-15'),
('Camila Barros','81970014444','Av Beberibe','1100',NULL,'Água Fria','Recife','PE','52110000','2026-04-18'),
('Felipe Moura','81970015555','Rua da Glória','55','Apto 302','Boa Vista','Recife','PE','50050010','2026-04-20'),
('Amanda Leal','81970016666','Av Cruz Cabuça','900',NULL,'Santo Amaro','Recife','PE','50040000','2026-04-22'),
('Gustavo Pires','81970017777','Rua do Riachuelo','33',NULL,'Derby','Recife','PE','52010000','2026-04-25'),
('Larissa Monteiro','81970018888','Av Gov. Agamenon','210','Loja 2','Graças','Recife','PE','52020010','2026-04-27'),
('Diego Cavalcante','81970019999','Rua Visconde','7',NULL,'Graças','Recife','PE','52011000','2026-04-30'),
('Marcelo Andrade','81970020000','Rua do Hospicio','142',NULL,'Boa Vista','Recife','PE','50060000','2026-05-02');
 
INSERT INTO entrega (cnpj_pizzaria, tempo_estimado, endereco_entrega, taxa) VALUES
('28456123000190', 40, 'Santo Amaro, Recife - PE', 5.00),
('28456123000190', 50, 'Boa Viagem, Recife - PE', 7.00),
('28456123000190', 35, 'Pina, Recife - PE', 5.00),
('28456123000190', 45, 'Boa Viagem, Recife - PE', 7.00),
('28456123000190', 55, 'Centro, Recife - PE', 6.00),
('28456123000190', 40, 'Boa Viagem, Recife - PE', 7.00),
('28456123000190', 50, 'Graças, Recife - PE', 6.00),
('28456123000190', 45, 'Boa Viagem, Recife - PE', 7.00),
('28456123000190', 60, 'Boa Viagem, Recife - PE', 7.00),
('28456123000190', 40, 'Madalena, Recife - PE', 5.00),
('28456123000190', 30, 'Santo Amaro, Recife - PE', 5.00),
('28456123000190', 45, 'Espinheiro, Recife - PE', 6.00),
('28456123000190', 35, 'Gracas, Recife - PE', 6.00),
('28456123000190', 50, 'Boa Viagem, Recife - PE', 7.00),
('28456123000190', 25, 'Centro, Recife - PE', 4.00),
('28456123000190', 40, 'Santo Amaro, Recife - PE', 5.00),
('28456123000190', 45, 'Derby, Recife - PE', 6.00),
('28456123000190', 55, 'Agua Fria, Recife - PE', 7.00),
('28456123000190', 35, 'Boa Vista, Recife - PE', 5.00),
('28456123000190', 40, 'Gracas, Recife - PE', 6.00);
 
ALTER TABLE bebida AUTO_INCREMENT = 1;
 
INSERT INTO bebida (nome, quantidade, preco, data_atualizacao) VALUES
('Refrigerante 2L', 50, 12.00, '2026-05-01'),
('Água Mineral', 100, 5.00, '2026-05-01'),
('Suco Natural 1L', 30, 10.00, '2026-04-20'),
('Guaraná 2L', 40, 11.00, '2026-05-03'),
('Coca Zero 2L', 35, 12.00, '2026-05-03'),
('Chá Gelado', 20, 9.00, '2026-04-15'),
('Água com Gás', 60, 5.00, '2026-05-01'),
('Suco de Uva 1L', 25, 10.00, '2026-04-28'),
('Energético 473ml', 30, 13.00, '2026-05-07'),
('Cerveja Lata', 80, 6.00, '2026-05-08'),
('Limonada 500ml', 40, 8.00, '2026-05-02'),
('Vinho Tinto 750ml', 15, 35.00, '2026-04-10'),
('Kombucha 350ml', 20, 14.00, '2026-05-05'),
('Isotônico 500ml', 50, 7.00, '2026-05-06'),
('Café Gelado 300ml', 30, 9.00, '2026-05-04'),
('Água de Coco 330ml', 45, 6.00, '2026-05-03'),
('Milkshake 400ml', 25, 16.00, '2026-04-28'),
('Capuccino Gelado 300ml', 20, 11.00, '2026-05-01'),
('Refrigerante Lata', 90, 5.00, '2026-05-08'),
('Água Tônica 350ml', 40, 6.00, '2026-05-09');
 
ALTER TABLE pizza AUTO_INCREMENT = 1;
 
INSERT INTO pizza (sabor, tipo, tamanho, borda, quantidade, preco) VALUES
('Calabresa', 'TRADICIONAL', 'M', 'Simples', 1, 30.00),
('Frango Catupiry', 'ESPECIAL', 'G', 'Catupiry', 1, 45.00),
('Margherita', 'TRADICIONAL', 'P', 'Simples', 1, 28.00),
('Quatro Queijos', 'ESPECIAL', 'M', 'Cheddar', 1, 42.00),
('Portuguesa', 'ESPECIAL', 'G', 'Simples', 1, 40.00),
('Napolitana', 'TRADICIONAL', 'M', 'Simples', 1, 26.00),
('Atum', 'ESPECIAL', 'G', 'Simples', 1, 44.00),
('Bacon', 'ESPECIAL', 'M', 'Simples', 1, 38.00),
('Vegetariana', 'ESPECIAL', 'P', 'Simples', 1, 32.00),
('Milho Bacon', 'TRADICIONAL', 'M', 'Simples', 1, 34.00),
('Carne Seca', 'ESPECIAL', 'G', 'Catupiry', 1, 48.00),
('Peperoni', 'ESPECIAL', 'M', 'Simples', 1, 36.00),
('Palmito', 'ESPECIAL', 'M', 'Simples', 1, 33.00),
('Camarão', 'ESPECIAL', 'G', 'Catupiry', 1, 55.00),
('Chocolate', 'ESPECIAL', 'P', 'Simples', 1, 29.00),
('Brócolis com Bacon', 'ESPECIAL', 'M', 'Cheddar', 1, 37.00),
('Tomate Seco', 'TRADICIONAL', 'P', 'Simples', 1, 27.00),
('Frango com Requeijao', 'ESPECIAL', 'G', 'Catupiry', 1, 46.00),
('Escarola', 'TRADICIONAL', 'M', 'Simples', 1, 31.00),
('Abobrinha com Feta', 'ESPECIAL', 'P', 'Simples', 1, 35.00),
('Lombo com Catupiry', 'ESPECIAL', 'G', 'Catupiry', 1, 50.00),
('Rucula com Tomate Seco', 'ESPECIAL', 'M', 'Simples', 1, 39.00),
('Nordestina', 'TRADICIONAL', 'G', 'Simples', 1, 43.00),
('Nutella com Morango', 'ESPECIAL', 'P', 'Simples', 1, 32.00);
 
INSERT INTO ingrediente (nome, preco) VALUES
('Calabresa fatiada', 8.00),
('Cebola roxa', 2.00),
('Mussarela', 6.00),
('Orégano', 1.00),
('Frango desfiado', 9.00),
('Catupiry original', 7.00),
('Milho', 2.00),
('Mussarela de búfala', 8.00),
('Tomate italiano', 3.00),
('Manjericão fresco', 2.00),
('Azeite extra virgem', 2.00),
('Provolone', 7.00),
('Parmesão', 6.00),
('Gorgonzola', 8.00),
('Presunto', 7.00),
('Ovo cozido', 2.00),
('Cebola', 2.00),
('Azeitona', 2.00),
('Alho frito', 2.00),
('Atum sólido', 9.00),
('Azeitona preta', 2.00),
('Bacon crocante', 9.00),
('Cebola caramelizada', 3.00),
('Pimentão', 2.00),
('Tomate', 3.00),
('Champignon', 4.00),
('Carne seca desfiada', 10.00),
('Peperoni', 9.00),
('Palmito', 6.00),
('Ervilha', 2.00),
('Camarão', 12.00),
('Chocolate ao leite', 8.00),
('Granulado', 2.00),
('Leite condensado', 3.00),
('Brocolis', 3.00),
('Requeijao cremoso', 5.00),
('Tomate seco', 4.00),
('Escarola', 3.00),
('Abobrinha', 2.00),
('Queijo feta', 6.00),
('Lombo canadense', 8.00),
('Rucula', 2.00),
('Carne de sol', 9.00),
('Macaxeira cozida', 3.00),
('Coalho grelhado', 5.00),
('Nutella', 7.00),
('Morango fatiado', 4.00);
 
INSERT INTO pizza_ingrediente (id_pizza, codigo_ingrediente) VALUES
(1,1),(1,2),(1,3),(1,4),
(2,5),(2,6),(2,7),(2,3),
(3,8),(3,9),(3,10),(3,11),
(4,3),(4,12),(4,13),(4,14),
(5,15),(5,16),(5,17),(5,18),(5,3),
(6,9),(6,13),(6,19),(6,4),
(7,20),(7,17),(7,21),(7,3),
(8,22),(8,3),(8,23),
(9,24),(9,17),(9,25),(9,26),(9,3),
(10,7),(10,22),(10,3),
(11,27),(11,2),(11,6),
(12,28),(12,3),(12,4),
(13,29),(13,30),(13,3),
(14,31),(14,6),(14,19),
(15,32),(15,33),(15,34),
(16,35),(16,22),(16,3),
(17,37),(17,9),(17,3),
(18,5),(18,36),(18,3),
(19,38),(19,3),(19,4),
(20,39),(20,40),(20,11),
(21,41),(21,6),(21,3),
(22,42),(22,37),(22,11),(22,3),
(23,43),(23,44),(23,45),(23,3),
(24,46),(24,47),(24,34);
 
INSERT INTO pedido (cnpj_pizzaria, id_cliente, codigo_entrega, forma_pagamento, valor_total, data_pedido) VALUES
('28456123000190', 1, 1, 'PIX', 47.00, '2026-05-01 18:30:00'),
('28456123000190', 2, 2, 'DINHEIRO', 57.00, '2026-05-02 19:10:00'),
('28456123000190', 3, 3, 'CARTAO', 43.00, '2026-05-03 20:00:00'),
('28456123000190', 4, 4, 'PIX', 60.00, '2026-05-04 18:45:00'),
('28456123000190', 5, 5, 'DINHEIRO', 58.00, '2026-05-05 21:15:00'),
('28456123000190', 6, 6, 'CARTAO', 42.00, '2026-05-06 19:50:00'),
('28456123000190', 7, 7, 'PIX', 55.00, '2026-05-07 20:20:00'),
('28456123000190', 8, 8, 'DINHEIRO', 51.00, '2026-05-08 18:10:00'),
('28456123000190', 9, 9, 'CARTAO', 52.00, '2026-05-09 22:00:00'),
('28456123000190', 10, 10, 'PIX', 45.00, '2026-05-10 19:40:00'),
('28456123000190', 11, 11, 'CARTAO', 52.00, '2026-05-01 20:00:00'),
('28456123000190', 12, 12, 'PIX', 63.00, '2026-05-02 18:45:00'),
('28456123000190', 13, 13, 'DINHEIRO', 49.00, '2026-05-03 21:30:00'),
('28456123000190', 14, 14, 'CARTAO', 71.00, '2026-05-04 19:15:00'),
('28456123000190', 15, 15, 'PIX', 38.00, '2026-05-05 20:50:00'),
('28456123000190', 16, 16, 'DINHEIRO', 55.00, '2026-05-06 18:20:00'),
('28456123000190', 17, 17, 'CARTAO', 60.00, '2026-05-07 21:00:00'),
('28456123000190', 18, 18, 'PIX', 68.00, '2026-05-08 19:30:00'),
('28456123000190', 19, 19, 'DINHEIRO', 44.00, '2026-05-09 20:10:00'),
('28456123000190', 20, 20, 'CARTAO', 57.00, '2026-05-10 18:55:00');
 
INSERT INTO pedido_pizza (id_pedido, id_pizza) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5),
(6,6),(7,7),(8,8),(9,9),(10,10),
(11,16),(12,17),(13,18),(14,19),(15,20),
(16,21),(17,22),(18,23),(19,24),(20,24);
 
INSERT INTO pedido_bebida (id_pedido, id_bebida) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5),
(6,6),(7,7),(8,8),(9,9),(10,10),
(11,11),(12,12),(13,13),(14,14),(15,15),
(16,16),(17,17),(18,18),(19,19),(20,20);
 
CREATE OR REPLACE VIEW vw_consulta_simples AS
  SELECT
    id_pizza AS codigo,
    sabor,
    tipo,
    tamanho,
    COALESCE(borda, 'Sem Borda') AS borda,
    preco,
    fn_categoria_pizza(id_pizza) AS categoria
  FROM pizza
  ORDER BY sabor;
 
CREATE OR REPLACE VIEW vw_clientes_cadastro_recente AS
  SELECT
    id_cliente,
    nome,
    telefone,
    cidade,
    estado,
    data_cadastro,
    DATE_FORMAT(data_cadastro, '%d/%m/%Y') AS cadastro_formatado,
    DATEDIFF(CURRENT_DATE, data_cadastro) AS dias_desde_cadastro
  FROM cliente
  WHERE data_cadastro >= DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)
  ORDER BY data_cadastro DESC;
 
CREATE OR REPLACE VIEW vw_bebidas_atualizadas_mes AS
  SELECT
    id_bebida,
    nome,
    quantidade,
    preco,
    data_atualizacao,
    DATE_FORMAT(data_atualizacao, '%d/%m/%Y') AS atualizacao_formatada,
    MONTH(data_atualizacao) AS mes,
    YEAR(data_atualizacao) AS ano
  FROM bebida
  WHERE MONTH(data_atualizacao) = MONTH(CURRENT_DATE)
    AND YEAR(data_atualizacao) = YEAR(CURRENT_DATE)
  ORDER BY data_atualizacao DESC;
 
CREATE OR REPLACE VIEW vw_pizzas_nome_formatado AS
  SELECT
    id_pizza,
    UPPER(sabor) AS sabor_maiusculo,
    LOWER(tipo) AS tipo_minusculo,
    CONCAT(UPPER(LEFT(sabor,1)), LOWER(SUBSTRING(sabor,2))) AS sabor_capitalizado,
    CASE tamanho
      WHEN 'P' THEN 'Pequena'
      WHEN 'M' THEN 'Média'
      WHEN 'G' THEN 'Grande'
    END AS tamanho_extenso,
    LENGTH(sabor) AS qtd_caracteres,
    preco
  FROM pizza
  ORDER BY sabor_maiusculo;
 
CREATE OR REPLACE VIEW vw_clientes_formatados AS
  SELECT
    id_cliente,
    UPPER(nome) AS nome_maiusculo,
    CONCAT(cidade, ' - ', estado) AS localidade,
    REPLACE(REPLACE(REPLACE(
      telefone, '(', ''), ')', ''), ' ', '') AS telefone_limpo,
    SUBSTRING(cep, 1, 5) AS cep_prefixo,
    CHAR_LENGTH(nome) AS tamanho_nome
  FROM cliente
  ORDER BY nome_maiusculo;
 
CREATE OR REPLACE VIEW vw_pedidos_completos AS
  SELECT
    p.id_pedido,
    p.data_pedido,
    c.nome AS cliente,
    c.telefone AS telefone_cliente,
    pz.nome AS pizzaria,
    CONCAT(c.rua, ', ', c.numero, ' - ', c.bairro) AS endereco_entrega,
    e.tempo_estimado AS tempo_entrega_min,
    e.taxa AS taxa_entrega,
    p.forma_pagamento,
    p.valor_total
  FROM pedido p
  INNER JOIN cliente c ON p.id_cliente = c.id_cliente
  INNER JOIN pizzaria pz ON p.cnpj_pizzaria = pz.cnpj
  LEFT JOIN entrega e ON p.codigo_entrega = e.codigo_entrega
  ORDER BY p.data_pedido DESC;
 
CREATE OR REPLACE VIEW vw_pizzas_com_ingredientes AS
  SELECT
    pz.id_pizza,
    pz.sabor,
    pz.tipo,
    pz.tamanho,
    pz.preco AS preco_venda,
    GROUP_CONCAT(i.nome ORDER BY i.nome SEPARATOR ', ') AS ingredientes,
    ROUND(SUM(i.preco), 2) AS custo_ingredientes,
    ROUND(pz.preco - SUM(i.preco), 2) AS margem_estimada
  FROM pizza pz
  INNER JOIN pizza_ingrediente pi ON pz.id_pizza = pi.id_pizza
  INNER JOIN ingrediente i ON pi.codigo_ingrediente = i.codigo
  GROUP BY pz.id_pizza, pz.sabor, pz.tipo, pz.tamanho, pz.preco
  ORDER BY margem_estimada DESC;

-- PROCEDURE 1: Registra um pedido completo
-- Calcula valor_total = preco_pizza + preco_bebiba + taxa_entrega
-- Uso: CALL sp_registrar_pedido(1, 1, 1, 1, 'PIX');

DELIMITER $$
CREATE PROCEDURE sp_registrar_pedido(
  IN p_id_cliente INT,
  IN p_cod_entrega INT,
  IN p_id_pizza INT,
  IN p_id_bebida INT,
  IN p_pagamento ENUM('PIX','DINHEIRO','CARTAO')
)
BEGIN
  DECLARE v_cnpj CHAR(14);
  DECLARE v_preco_pizza DECIMAL(10,2);
  DECLARE v_preco_beb DECIMAL(10,2);
  DECLARE v_taxa DECIMAL(10,2);
  DECLARE v_total DECIMAL(10,2);
  DECLARE v_id_pedido INT;
 
  -- Busca o CNPJ da unica pizzaria
  SELECT cnpj INTO v_cnpj FROM pizzaria LIMIT 1;
 
  -- Busca os precos
  SELECT preco INTO v_preco_pizza FROM pizza   WHERE id_pizza  = p_id_pizza  LIMIT 1;
  SELECT preco INTO v_preco_beb FROM bebida  WHERE id_bebida = p_id_bebida LIMIT 1;
  SELECT taxa  INTO v_taxa FROM entrega WHERE codigo_entrega = p_cod_entrega LIMIT 1;
 
  -- Calcula total
  SET v_total = IFNULL(v_preco_pizza, 0) + IFNULL(v_preco_beb, 0) + IFNULL(v_taxa, 0);

  -- Insere o pedido
  INSERT INTO pedido (cnpj_pizzaria, id_cliente, codigo_entrega, forma_pagamento, valor_total)
  VALUES (v_cnpj, p_id_cliente, p_cod_entrega, p_pagamento, v_total);
 
  SET v_id_pedido = LAST_INSERT_ID();
 
  -- Associa pizza e bebida ao pedido
  INSERT INTO pedido_pizza  (id_pedido, id_pizza) VALUES (v_id_pedido, p_id_pizza);
  INSERT INTO pedido_bebida (id_pedido, id_bebida) VALUES (v_id_pedido, p_id_bebida);
 
  -- Retorna resumo do pedido criado
  SELECT fn_resumo_pedido(v_id_pedido) AS resumo_pedido;
END$$
 

-- PROCEDURE 2: Retorna todos os pedidos entre duas datas com dados completos, deve se informar a data na seguencia de ano-mes-dia.
-- Uso: CALL sp_relatorio_pedidos_periodo('2026-05-01', '2026-05-10');

CREATE PROCEDURE sp_relatorio_pedidos_periodo(
  IN p_data_inicio DATE,
  IN p_data_fim DATE
)
BEGIN
  SELECT
    p.id_pedido,
    DATE_FORMAT(p.data_pedido, '%d/%m/%Y %H:%i') AS data_pedido,
    c.nome AS cliente,
    fn_formatar_telefone(c.telefone) AS telefone,
    pz.nome AS pizzaria,
    GROUP_CONCAT(DISTINCT pi.sabor ORDER BY pi.sabor SEPARATOR ', ') AS pizzas,
    GROUP_CONCAT(DISTINCT b.nome ORDER BY b.nome SEPARATOR ', ') AS bebidas,
    p.forma_pagamento,
    e.taxa AS taxa_entrega,
    p.valor_total
  FROM pedido p
  INNER JOIN cliente c ON p.id_cliente = c.id_cliente
  INNER JOIN pizzaria pz ON p.cnpj_pizzaria = pz.cnpj
  LEFT JOIN entrega e ON p.codigo_entrega = e.codigo_entrega
  LEFT JOIN pedido_pizza pp ON p.id_pedido = pp.id_pedido
  LEFT JOIN pizza pi ON pp.id_pizza = pi.id_pizza
  LEFT JOIN pedido_bebida pb ON p.id_pedido = pb.id_pedido
  LEFT JOIN bebida b ON pb.id_bebida = b.id_bebida
  WHERE DATE(p.data_pedido) BETWEEN p_data_inicio AND p_data_fim
  GROUP BY p.id_pedido, p.data_pedido, c.nome, c.telefone,
           pz.nome, p.forma_pagamento, e.taxa, p.valor_total
  ORDER BY p.data_pedido;
END$$

-- PROCEDURE 3: Atualiza a bebida, valor e quantidade.
-- CALL sp_atualizar_bebida(1, 15.00, 40); 

DELIMITER $$
CREATE PROCEDURE sp_atualizar_bebida(
    IN p_id_bebida INT,
    IN p_novo_preco DECIMAL(10,2),
    IN p_nova_quantidade INT
)
BEGIN
    -- Validação de estoque
    IF p_nova_quantidade < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Estoque insuficiente: quantidade nao pode ser negativa.';
    END IF;

    UPDATE bebida
       SET preco = p_novo_preco,
           quantidade = p_nova_quantidade,
           data_atualizacao = CURRENT_DATE
     WHERE id_bebida = p_id_bebida;

END$$
DELIMITER ; 
 
 -- PROCEDURE 4: Registra pizzas novas (sabor, tipo, tamanho, bordar e valor)
 -- CALL sp_inserir_pizza('Moda da Casa', 'ESPECIAL', 'G', 'Cheddar', 52.00);
 DELIMITER $$
CREATE PROCEDURE sp_inserir_pizza(
    IN p_sabor VARCHAR(120),
    IN p_tipo ENUM('TRADICIONAL','ESPECIAL'),
    IN p_tamanho ENUM('P','M','G'),
    IN p_borda VARCHAR(80),
    IN p_preco DECIMAL(10,2)
)
BEGIN
    IF p_preco <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Preco invalido: o preco da pizza deve ser maior que zero.';
    END IF;

    INSERT INTO pizza (sabor, tipo, tamanho, borda, preco)
    VALUES (p_sabor, p_tipo, p_tamanho, p_borda, p_preco);

END$$
DELIMITER ;
 
 -- PROCEDURE 5: Atualiza o preço da pizza (id da pizza e valor novo)
 -- CALL sp_atualizar_preco_pizza(3, 35.00);
 
 DELIMITER $$
CREATE PROCEDURE sp_atualizar_preco_pizza(
    IN p_id_pizza INT,
    IN p_novo_preco DECIMAL(10,2)
)
BEGIN
    IF p_novo_preco <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Preco invalido: o preco da pizza deve ser maior que zero.';
    END IF;

    UPDATE pizza
       SET preco = p_novo_preco
     WHERE id_pizza = p_id_pizza;

END$$
DELIMITER ;
 
DELIMITER $$

-- TRIGGER 1: Atualiza data_atualizacao automaticamente
CREATE TRIGGER trg_atualizar_data_bebida
BEFORE UPDATE ON bebida
FOR EACH ROW
BEGIN
  IF NEW.preco <> OLD.preco OR NEW.quantidade <> OLD.quantidade THEN
    SET NEW.data_atualizacao = CURRENT_DATE;
  END IF;
END$$

-- TRIGGER 2: Impede estoque negativo
CREATE TRIGGER trg_bebida_estoque_negativo
BEFORE UPDATE ON bebida
FOR EACH ROW
BEGIN
  IF NEW.quantidade < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Estoque insuficiente: quantidade nao pode ser negativa.';
  END IF;
END$$

-- TRIGGER 3: Preço inválido no INSERT de pizza
CREATE TRIGGER trg_pizza_preco_invalido_insert
BEFORE INSERT ON pizza
FOR EACH ROW
BEGIN
  IF NEW.preco <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Preco invalido: o preco da pizza deve ser maior que zero.';
  END IF;
END$$

-- TRIGGER 4: Preço inválido no UPDATE de pizza
CREATE TRIGGER trg_pizza_preco_invalido_update
BEFORE UPDATE ON pizza
FOR EACH ROW
BEGIN
  IF NEW.preco <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Preco invalido: o preco da pizza deve ser maior que zero.';
  END IF;
END$$

DELIMITER ;