# MIPS multiciclo com hierarquia de memória em VHDL

Processador MIPS multiciclo descrito em VHDL e avaliado com três modelos de memória: memória ideal sem atraso (MP-0), memória principal com 8 ciclos de atraso e uma hierarquia com memória principal e **cache L1**. O objetivo é comparar o desempenho de cada modelo executando programas em assembly MIPS.

## Contexto

Trabalho prático da disciplina **Organização e Arquitetura de Computadores** (PUCRS), 4º semestre de Engenharia de Computação. O processador base com a MP-0 foi fornecido pela disciplina. A memória com atraso, a cache e a máquina de estados de controle foram desenvolvidas pelo grupo.

## Autores

- Lukas Ely
- Gabriel Kaizer de Menezes
- Emanuel Barros

## Tecnologias

- VHDL
- ModelSim / Questa para simulação
- MARS para montar os programas MIPS e gerar os dumps de memória

## Detalhes da cache

- 4 linhas com blocos de 8 palavras (mapeamento direto)
- Controle de leitura e escrita por uma máquina de 4 estados
- Programas de teste: média de vetor, leitura de matriz por linha e por coluna, detecção de overflow e bubble sort

A análise completa dos resultados está em [`docs/relatorio.pdf`](docs/relatorio.pdf).

## Como simular

Cada variante tem o seu script do ModelSim. Exemplo com a cache:

```sh
cd MIPS_Cache
vsim -do sim.do
```

Troque `MIPS_Cache` por `MIPS_MP` (memória com atraso) ou `MIPS_MultiCiclo_Hold` para as outras variantes. Os programas usados estão em `Assembly/` e os dumps correspondentes em `Dumps/`.

## Estrutura de pastas

```
.
├── Assembly/               programas de teste em assembly MIPS
├── Dumps/                  dumps de memória gerados no MARS
├── MIPS_MultiCiclo_Hold/   processador com sinal de espera para a memória
├── MIPS_MP/                processador com memória principal com atraso
├── MIPS_Cache/             processador com memória principal e cache L1
└── docs/relatorio.pdf      relatório com a comparação de desempenho
```
