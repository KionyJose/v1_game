# Piloto local: Minecraft Dungeons II [FitGirl Repack]

Teste realizado em 2026-10-04, mantendo a instalação direta em `Jogo` e usando
`Jogo-Silent-Teste` para o instalador original. Os pacotes originais não foram
alterados. A biblioteca principal continuou apontando para `Jogo/Dungeons.exe`.

## Resultado observado

- Instalador identificado no log: Inno Setup 5.5.1.ee2 (u).
- Flags: `/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOICONS /TASKS=""`,
  destino explícito e log.
- Código de saída: 0. Duração externa total: **33min27s**.
- Extração do conteúdo terminou aproximadamente 8min39s após o início do log.
  A mensagem inicial de sucesso do Inno não significava que o jogo estava pronto.
- QuickSFV continuou por cerca de 11min22s; depois foram chamados o instalador
  web DirectX, um site do repack e `host.cmd`.
- O script tentava cadastrar redirecionamentos no arquivo hosts. Os arquivos
  hosts locais examinados mantinham tamanho 824 bytes e data 2026-05-20;
  não foi observada alteração durante este piloto.
- Foi criado um atalho no desktop público mesmo com `/NOICONS`.
- Uma verificação independente posterior conferiu todo o manifesto MD5 e
  identificou `Jogo-Silent-Teste/Dungeons.exe` como executável de entrada.
  Essa verificação levou aproximadamente 2min31s e não está incluída nos 33min27s.

O teste completo de extração direta também passou no manifesto e cadastrou
`Jogo/Dungeons.exe` como primeiro jogo. Não há uma medição equivalente do seu
tempo total; não se deve calcular uma porcentagem de ganho usando somente
o tempo de verificação ou somente o trecho de extração do instalador.

## Decisão para o launcher

Manter a extração direta no botão **Jogar**. Oferecer **Instalar silent** como
comparação experimental separada, com status, cancelamento, verificação e
relatório de duração. O helper novo dispensa os auxiliares QuickSFV/DirectX
somente dentro do seu próprio Job Object; essa melhoria passou nos testes
nativos de processo e cancelamento, mas ainda não foi medida com outra
instalação completa deste pacote.

As flags padrão do Inno não suprimem necessariamente scripts customizados,
abertura de site ou outras ações do instalador original. A extração direta é
o método validado que evita essas etapas. A elevação solicitada pelo instalador
usa a autorização convencional do Windows.
