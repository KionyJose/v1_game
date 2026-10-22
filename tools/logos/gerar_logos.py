"""Gera os PNGs de assets/Lojas a partir dos ícones do Simple Icons (CC0).

Renderiza o path do SVG direto com PIL: não há ImageMagick nem Inkscape nesta
máquina, e `convert` aqui é o utilitário de sistema de arquivos do Windows.
Preenchimento nonzero (o padrão do SVG), supersample 4x e redução Lanczos.
"""
import math
import os
import re
import urllib.request

from PIL import Image

SAIDA = os.path.join('assets', 'Lojas')
LADO = 512
SUPER = 4
MARGEM = 0.12  # respiro proporcional dentro do quadrado

NUMERO = re.compile(r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?')


class Leitor:
    """Cursor sobre o atributo `d`.

    Um tokenizador que só devolve números não serve: nos arcos as duas flags
    podem vir grudadas no próximo número (`a5 5 0 11-3 3`), e "11" viraria um
    número só. Por isso a leitura é posicional, e a flag é lida como um dígito.
    """

    def __init__(self, d):
        self.d = d
        self.i = 0

    def _pular(self):
        while self.i < len(self.d) and self.d[self.i] in ', \t\r\n':
            self.i += 1

    def fim(self):
        self._pular()
        return self.i >= len(self.d)

    def comando(self):
        self._pular()
        if self.i < len(self.d) and self.d[self.i].isalpha():
            c = self.d[self.i]
            self.i += 1
            return c
        return None

    def numero(self):
        self._pular()
        m = NUMERO.match(self.d, self.i)
        if not m:
            raise ValueError('número esperado em %d: %r'
                             % (self.i, self.d[self.i:self.i + 12]))
        self.i = m.end()
        return float(m.group())

    def flag(self):
        self._pular()
        c = self.d[self.i]
        if c not in '01':
            raise ValueError('flag de arco esperada em %d: %r' % (self.i, c))
        self.i += 1
        return int(c)


def bezier3(p0, p1, p2, p3, n=24):
    for i in range(1, n + 1):
        t = i / n
        u = 1 - t
        yield (u * u * u * p0[0] + 3 * u * u * t * p1[0]
               + 3 * u * t * t * p2[0] + t * t * t * p3[0],
               u * u * u * p0[1] + 3 * u * u * t * p1[1]
               + 3 * u * t * t * p2[1] + t * t * t * p3[1])


def bezier2(p0, p1, p2, n=18):
    for i in range(1, n + 1):
        t = i / n
        u = 1 - t
        yield (u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
               u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])


def arco(p0, rx, ry, rot, grande, varrer, p1, n=36):
    """Arco elíptico SVG: endpoint -> centro, conforme a especificação F.6."""
    if rx == 0 or ry == 0 or p0 == p1:
        return [p1]
    rx, ry = abs(rx), abs(ry)
    fi = math.radians(rot)
    cosf, sinf = math.cos(fi), math.sin(fi)
    dx2, dy2 = (p0[0] - p1[0]) / 2, (p0[1] - p1[1]) / 2
    x1 = cosf * dx2 + sinf * dy2
    y1 = -sinf * dx2 + cosf * dy2
    lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
    if lam > 1:
        escala = math.sqrt(lam)
        rx, ry = rx * escala, ry * escala
    num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    den = rx * rx * y1 * y1 + ry * ry * x1 * x1
    fator = math.sqrt(max(num, 0) / den) if den else 0
    if grande == varrer:
        fator = -fator
    cx1 = fator * rx * y1 / ry
    cy1 = -fator * ry * x1 / rx
    cx = cosf * cx1 - sinf * cy1 + (p0[0] + p1[0]) / 2
    cy = sinf * cx1 + cosf * cy1 + (p0[1] + p1[1]) / 2

    def angulo(ux, uy, vx, vy):
        pon = ux * vx + uy * vy
        mod = math.hypot(ux, uy) * math.hypot(vx, vy)
        ang = math.acos(max(-1.0, min(1.0, pon / mod))) if mod else 0.0
        return -ang if ux * vy - uy * vx < 0 else ang

    t1 = angulo(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
    dt = angulo((x1 - cx1) / rx, (y1 - cy1) / ry,
                (-x1 - cx1) / rx, (-y1 - cy1) / ry)
    if not varrer and dt > 0:
        dt -= 2 * math.pi
    elif varrer and dt < 0:
        dt += 2 * math.pi
    pontos = []
    for i in range(1, n + 1):
        t = t1 + dt * i / n
        ct, st = math.cos(t), math.sin(t)
        pontos.append((cosf * rx * ct - sinf * ry * st + cx,
                       sinf * rx * ct + cosf * ry * st + cy))
    return pontos


def subcaminhos(d):
    """Converte o atributo `d` em polígonos fechados."""
    r = Leitor(d)
    atual = []
    saida = []
    pos = (0.0, 0.0)
    inicio = (0.0, 0.0)
    cmd = None
    ultimo_c = None
    ultimo_q = None

    def fechar():
        if len(atual) > 2:
            saida.append(list(atual))
        atual.clear()

    while not r.fim():
        c = r.comando()
        if c is not None:
            cmd = c
        if cmd is None:
            raise ValueError('path sem comando inicial')
        if cmd in 'Zz':
            fechar()
            pos = inicio
            continue
        rel = cmd.islower()
        maior = cmd.upper()

        if maior == 'M':
            x, y = r.numero(), r.numero()
            if rel:
                x, y = pos[0] + x, pos[1] + y
            fechar()
            pos = inicio = (x, y)
            atual.append(pos)
            # Coordenadas extras depois de um M são linhas, como manda o SVG.
            cmd = 'l' if rel else 'L'
            ultimo_c = ultimo_q = None
        elif maior == 'L':
            x, y = r.numero(), r.numero()
            if rel:
                x, y = pos[0] + x, pos[1] + y
            pos = (x, y)
            atual.append(pos)
            ultimo_c = ultimo_q = None
        elif maior == 'H':
            x = r.numero()
            pos = (pos[0] + x if rel else x, pos[1])
            atual.append(pos)
            ultimo_c = ultimo_q = None
        elif maior == 'V':
            y = r.numero()
            pos = (pos[0], pos[1] + y if rel else y)
            atual.append(pos)
            ultimo_c = ultimo_q = None
        elif maior in 'CS':
            if maior == 'C':
                x1, y1 = r.numero(), r.numero()
                if rel:
                    x1, y1 = pos[0] + x1, pos[1] + y1
            else:
                x1, y1 = ((2 * pos[0] - ultimo_c[0], 2 * pos[1] - ultimo_c[1])
                          if ultimo_c else pos)
            x2, y2 = r.numero(), r.numero()
            x, y = r.numero(), r.numero()
            if rel:
                x2, y2 = pos[0] + x2, pos[1] + y2
                x, y = pos[0] + x, pos[1] + y
            if not atual:
                atual.append(pos)
            atual.extend(bezier3(pos, (x1, y1), (x2, y2), (x, y)))
            ultimo_c = (x2, y2)
            ultimo_q = None
            pos = (x, y)
        elif maior in 'QT':
            if maior == 'Q':
                x1, y1 = r.numero(), r.numero()
                if rel:
                    x1, y1 = pos[0] + x1, pos[1] + y1
            else:
                x1, y1 = ((2 * pos[0] - ultimo_q[0], 2 * pos[1] - ultimo_q[1])
                          if ultimo_q else pos)
            x, y = r.numero(), r.numero()
            if rel:
                x, y = pos[0] + x, pos[1] + y
            if not atual:
                atual.append(pos)
            atual.extend(bezier2(pos, (x1, y1), (x, y)))
            ultimo_q = (x1, y1)
            ultimo_c = None
            pos = (x, y)
        elif maior == 'A':
            rx, ry, rot = r.numero(), r.numero(), r.numero()
            grande, varrer = r.flag(), r.flag()
            x, y = r.numero(), r.numero()
            if rel:
                x, y = pos[0] + x, pos[1] + y
            if not atual:
                atual.append(pos)
            atual.extend(arco(pos, rx, ry, rot, grande, varrer, (x, y)))
            pos = (x, y)
            ultimo_c = ultimo_q = None
        else:
            raise ValueError('comando nao suportado: %r' % cmd)
    fechar()
    return saida


def mascara(poligonos, lado, vb):
    """Rasteriza com regra nonzero, que é o padrão do SVG."""
    vbx, vby, vbw, vbh = vb
    util = lado * (1 - 2 * MARGEM)
    escala = util / max(vbw, vbh)
    offx = (lado - vbw * escala) / 2 - vbx * escala
    offy = (lado - vbh * escala) / 2 - vby * escala

    arestas = []
    for poli in poligonos:
        pts = [(x * escala + offx, y * escala + offy) for x, y in poli]
        for k in range(len(pts)):
            (x0, y0), (x1, y1) = pts[k], pts[(k + 1) % len(pts)]
            if y0 == y1:
                continue
            arestas.append((min(y0, y1), max(y0, y1), x0, y0, x1, y1,
                            1 if y1 > y0 else -1))
    buf = bytearray(lado * lado)
    for py in range(lado):
        yc = py + 0.5
        cruz = []
        for ymin, ymax, x0, y0, x1, y1, direcao in arestas:
            if yc < ymin or yc >= ymax:
                continue
            cruz.append((x0 + (yc - y0) * (x1 - x0) / (y1 - y0), direcao))
        if not cruz:
            continue
        cruz.sort()
        enrola = 0
        linha = py * lado
        for k in range(len(cruz) - 1):
            enrola += cruz[k][1]
            if enrola == 0:
                continue
            a = max(0, int(round(cruz[k][0])))
            b = min(lado, int(round(cruz[k + 1][0])))
            if b > a:
                buf[linha + a:linha + b] = b'\xff' * (b - a)
    return Image.frombytes('L', (lado, lado), bytes(buf))


def baixar_svg(slug):
    url = 'https://cdn.simpleicons.org/' + slug
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    return urllib.request.urlopen(req, timeout=30).read().decode('utf8')


def viewbox(svg):
    m = re.search(r'viewBox="([\d.\-\s]+)"', svg)
    return tuple(float(v) for v in m.group(1).split()) if m else (0, 0, 24, 24)


def gerar(nome, slug, cor=(255, 255, 255)):
    svg = baixar_svg(slug)
    vb = viewbox(svg)
    polis = []
    for d in re.findall(r'<path[^>]*\sd="([^"]+)"', svg):
        polis.extend(subcaminhos(d))
    alfa = mascara(polis, LADO * SUPER, vb).resize((LADO, LADO),
                                                   Image.LANCZOS)
    img = Image.new('RGBA', (LADO, LADO), cor + (0,))
    img.putalpha(alfa)
    caminho = os.path.join(SAIDA, nome + '.png')
    img.save(caminho, optimize=True)
    opacos = sum(1 for p in alfa.convert('L').tobytes() if p > 8)
    print('%-12s %-14s %6d bytes  cobertura %.1f%%'
          % (nome, slug, os.path.getsize(caminho),
             100 * opacos / (LADO * LADO)))


# Nome do arquivo em assets/Lojas -> slug no Simple Icons.
# Microsoft, Blizzard e ModDB foram retirados do Simple Icons a pedido das
# marcas; a Blizzard entra como Battle.net, que é a loja de fato.
DO_SIMPLE_ICONS = [
    ('steam', 'steam'),
    ('gog', 'gogdotcom'),
    ('epic', 'epicgames'),
    ('ea', 'ea'),
    ('ubisoft', 'ubisoft'),
    ('blizzard', 'battledotnet'),
    ('itchio', 'itchdotio'),
]


def microsoft():
    """Quatro quadrados iguais com folga: a geometria exata do logotipo.

    Vai nas cores oficiais porque em branco viraria só quatro quadrados e a
    marca se perderia; as demais são monocromáticas.
    """
    from PIL import ImageDraw
    margem = int(LADO * 0.12)
    lado = int((LADO - 2 * margem) * 0.47)
    folga = (LADO - 2 * margem) - 2 * lado
    img = Image.new('RGBA', (LADO, LADO), (0, 0, 0, 0))
    desenho = ImageDraw.Draw(img)
    cores = [(0xF2, 0x50, 0x22), (0x7F, 0xBA, 0x00),
             (0x00, 0xA4, 0xEF), (0xFF, 0xB9, 0x00)]
    for i, (cx, cy) in enumerate([(0, 0), (1, 0), (0, 1), (1, 1)]):
        x = margem + cx * (lado + folga)
        y = margem + cy * (lado + folga)
        desenho.rectangle([x, y, x + lado, y + lado], fill=cores[i] + (255,))
    img.save(os.path.join(SAIDA, 'microsoft.png'), optimize=True)
    print('%-12s %-14s %6d bytes' % ('microsoft', '(geometria)',
          os.path.getsize(os.path.join(SAIDA, 'microsoft.png'))))


def descobrir():
    """Bússola do Descobrir: marca nossa, desenhada aqui.

    Não é marca de terceiro, então não vem do Simple Icons. Um anel e uma
    agulha de dois gomos — a leitura clássica de "explorar" — em branco, como
    as demais logos monocromáticas.
    """
    import math
    from PIL import ImageDraw
    lado = LADO * SUPER
    img = Image.new('L', (lado, lado), 0)
    desenho = ImageDraw.Draw(img)
    centro = lado / 2
    raio = lado * (0.5 - MARGEM)
    grossura = lado * 0.062
    desenho.ellipse(
        [centro - raio, centro - raio, centro + raio, centro + raio],
        outline=255, width=int(grossura))

    # Agulha: dois gomos opostos, girados 45 graus.
    comprimento = raio * 0.62
    meio = raio * 0.2
    angulo = math.radians(-45)

    def girar(x, y):
        return (centro + x * math.cos(angulo) - y * math.sin(angulo),
                centro + x * math.sin(angulo) + y * math.cos(angulo))

    desenho.polygon([girar(0, -comprimento), girar(meio, 0), girar(0, 0)],
                    fill=255)
    desenho.polygon([girar(0, -comprimento), girar(-meio, 0), girar(0, 0)],
                    fill=255)
    desenho.polygon([girar(0, comprimento), girar(meio, 0), girar(0, 0)],
                    fill=255)
    desenho.polygon([girar(0, comprimento), girar(-meio, 0), girar(0, 0)],
                    fill=255)

    alfa = img.resize((LADO, LADO), Image.LANCZOS)
    final = Image.new('RGBA', (LADO, LADO), (255, 255, 255, 0))
    final.putalpha(alfa)
    caminho = os.path.join(SAIDA, 'descobrir.png')
    final.save(caminho, optimize=True)
    print('%-12s %-14s %6d bytes' % ('descobrir', '(geometria)',
          os.path.getsize(caminho)))


def interna():
    """A Loja Interna usa o ícone do próprio aplicativo."""
    origem = os.path.join('assets', 'IconeAppV1.png')
    img = Image.open(origem).convert('RGBA')
    if img.size != (LADO, LADO):
        img = img.resize((LADO, LADO), Image.LANCZOS)
    img.save(os.path.join(SAIDA, 'interna.png'), optimize=True)
    print('%-12s %-14s %6d bytes' % ('interna', origem,
          os.path.getsize(os.path.join(SAIDA, 'interna.png'))))


if __name__ == '__main__':
    os.makedirs(SAIDA, exist_ok=True)
    for nome, slug in DO_SIMPLE_ICONS:
        gerar(nome, slug)
    microsoft()
    descobrir()
    interna()
