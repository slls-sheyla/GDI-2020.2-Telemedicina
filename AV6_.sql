-- Resetando a sessão.
DROP TABLE tb_medicos;
DROP TABLE tb_pacientes;
DROP TYPE tp_medico;
DROP TYPE tp_paciente;
DROP TYPE tp_pessoa;
DROP TYPE tp_telefones;
DROP TYPE tp_telefone;
DROP TYPE tp_endereco;

-- Criando os tipos que serão usados.
CREATE TYPE tp_telefone AS OBJECT(
    ddd VARCHAR2(2),
    numero VARCHAR(9),
    MEMBER FUNCTION prettyTel RETURN VARCHAR2,
    MAP MEMBER FUNCTION rawTel RETURN VARCHAR2
);
/

CREATE TYPE BODY tp_telefone AS
    MEMBER FUNCTION prettyTel RETURN VARCHAR2 IS
        BEGIN
            IF LENGTH(numero) = 9 THEN
                RETURN '(' || ddd || ') ' || SUBSTR(numero, 1, 1) || ' ' ||
                        SUBSTR(numero, 2, 5) || '-' || SUBSTR(numero, 6, 9);
            ELSE
                RETURN '(' || ddd || ') ' || SUBSTR(numero, 1, 4) || '-' ||
                        SUBSTR(numero, 5, 8);
            END IF;
        END;
    MAP MEMBER FUNCTION rawTel RETURN VARCHAR2 IS
        BEGIN
            RETURN ddd || numero;
        END;
END;
/

CREATE TYPE tp_telefones AS VARRAY(2) OF tp_telefone;
/

CREATE TYPE tp_endereco AS OBJECT(
    logradouro VARCHAR2(30),
    numero VARCHAR2(4),
    complemento VARCHAR2(30),
    bairro VARCHAR2(15),
    cidade VARCHAR2(15),
    estado VARCHAR2(2),
    cep VARCHAR2(8),
    MEMBER FUNCTION prettyEnd RETURN VARCHAR2
);
/

CREATE TYPE BODY tp_endereco AS
    MEMBER FUNCTION prettyEnd RETURN VARCHAR2 IS
        BEGIN
            RETURN logradouro || ' - nº ' || numero || ' (' || complemento || '), ' ||
                    bairro || ', ' || cidade || ' - ' || estado || '. CEP: ' ||
                    SUBSTR(cep, 1, 3) || '.' || SUBSTR(cep, 4, 6) || SUBSTR(cep, 7, 8) || '.';
        END;
END;
/

CREATE TYPE tp_pessoa AS OBJECT(
    cpf VARCHAR2(11),
    nome VARCHAR2(30),
    sexo VARCHAR2(1),
    dataNascimento DATE,
    telefones tp_telefones,
    endereco tp_endereco,
    MEMBER FUNCTION getIdade RETURN NUMBER
)NOT FINAL;
/

CREATE TYPE BODY tp_pessoa AS
    MEMBER FUNCTION getIdade RETURN NUMBER IS
        BEGIN
            RETURN TRUNC((MONTHS_BETWEEN(SYSDATE, dataNascimento)/12), 0);
        END;
END;
/

CREATE TYPE tp_paciente UNDER tp_pessoa(
    sus VARCHAR2(4),
    plano VARCHAR2(15),
    MEMBER FUNCTION prettyPac RETURN VARCHAR2
);
/

CREATE TYPE BODY tp_paciente AS
    MEMBER FUNCTION prettyPac RETURN VARCHAR2 IS
        ident VARCHAR2(500);
        BEGIN
            ident := nome || '. CPF: ' || cpf || '. Idade: ' || self.getIdade() ||
                        '. Fones: ' || telefones(1).prettyTel() || ', ' || telefones(2).prettyTel() ||
                        '. Endereço: ' || endereco.prettyEnd() || ' Número do SUS: ' || sus ||
                        '. Plano de Saúde: ' || plano || '.';
            IF sexo = 'M' THEN
                RETURN 'Sr. ' || ident;
            ELSE
                RETURN 'Sra. ' || ident;
            END IF;
        END;
END;
/

CREATE TYPE tp_medico UNDER tp_pessoa(
    crm VARCHAR2(4),
    especialidade VARCHAR2(15),
    MEMBER FUNCTION prettyMed RETURN VARCHAR2
);
/

CREATE TYPE BODY tp_medico AS
    MEMBER FUNCTION prettyMed RETURN VARCHAR2 IS
        ident VARCHAR2(500);
        BEGIN
            ident := nome || ' - ' || especialidade || '. CRM: ' || crm || '. Fones: ' ||
                        telefones(1).prettyTel() || ', ' || telefones(2).prettyTel();
            IF sexo = 'M' THEN
                RETURN 'Dr. ' || ident;
            ELSE
                RETURN 'Dra. ' || ident;
            END IF;
        END;
END;
/

-- Criando as tabelas que serão usadas.
CREATE TABLE tb_pacientes OF tp_paciente(
    UNIQUE (sus),
    PRIMARY KEY (cpf)
);

CREATE TABLE tb_medicos OF tp_medico(
    UNIQUE (crm),
    PRIMARY KEY (cpf)
);

-- Povoando as tabelas.
INSERT INTO tb_pacientes VALUES (tp_paciente('13215654844', 'João da Silva', 'M', TO_DATE('27/05/1993', 'dd/mm/yyyy'),
                                                tp_telefones(tp_telefone('81', '34458888'), tp_telefone('81', '988775456')),
                                                tp_endereco('Rua Fernando Pessoa', '42', 'casa b', 'Centro', 'São Macaparana', 'RO', '51843450'),
                                                '2541', 'Bradesco'));

INSERT INTO tb_medicos VALUES (tp_medico('55643389715', 'Marina Cabral', 'F', TO_DATE('15/09/1984', 'dd/mm/yyyy'),
                                            tp_telefones(tp_telefone('87', '21263014'), tp_telefone('87', '994172114')),
                                            tp_endereco('Avenida São Cristovão', '84', 'apt 2001', 'Barra Grande', 'Juracema', 'RN', '58940052'),
                                            '5017', 'Cardiologista'));

-- Manipulando as tabelas.
SELECT p.prettyPac() AS Dados_do_Paciente FROM tb_pacientes p;

SELECT m.prettyMed() AS Dados_do_Medico FROM tb_medicos m;