"""Generate the complete Word guide from workshop pages and executable sources."""
from pathlib import Path
import json
import re
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH

root = Path(__file__).resolve().parents[1]
doc = Document()
section = doc.sections[0]
section.page_width, section.page_height = Inches(8.5), Inches(11)
section.left_margin = section.right_margin = Inches(.7)
section.top_margin = section.bottom_margin = Inches(.65)
section.header_distance = section.footer_distance = Inches(.3)
for name in ('Normal', 'Title', 'Subtitle', 'Heading 1', 'Heading 2', 'Heading 3'):
    style = doc.styles[name]
    style.font.name = 'Calibri'
    style.font.color.rgb = RGBColor(0, 0, 0)
doc.styles['Caption'].font.color.rgb = RGBColor(0, 0, 0)
doc.styles['Normal'].font.size = Pt(10.5)
doc.styles['Normal'].paragraph_format.space_after = Pt(5)
doc.styles['Normal'].paragraph_format.line_spacing = 1.05
doc.styles['Title'].font.size = Pt(24)
for name, size in (('Heading 1', 17), ('Heading 2', 13), ('Heading 3', 11)):
    doc.styles[name].font.size = Pt(size)
    doc.styles[name].paragraph_format.keep_with_next = True
code = doc.styles.add_style('Lab Code', 1)
code.font.name = 'Liberation Mono'
code.font.size = Pt(8)
code.paragraph_format.line_spacing = Pt(9.6)
code.paragraph_format.space_before = Pt(4)
code.paragraph_format.space_after = Pt(6)
code.paragraph_format.left_indent = Inches(.08)
code.paragraph_format.widow_control = True


def inline(p, text):
    for token in re.split(r'(\[[^\]]+\]\([^)]+\)|`[^`]+`|\*\*[^*]+\*\*)', text):
        link = re.fullmatch(r'\[([^\]]+)\]\(([^)]+)\)', token)
        if link and link[2].startswith(('https://', 'http://')):
            h = OxmlElement('w:hyperlink')
            h.set(qn('r:id'), p.part.relate_to(link[2],
                  'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink',
                  is_external=True))
            r = OxmlElement('w:r')
            pr = OxmlElement('w:rPr')
            color = OxmlElement('w:color')
            color.set(qn('w:val'), '0563C1')
            pr.append(color)
            r.append(pr)
            t = OxmlElement('w:t')
            t.text = link[1]
            r.append(t)
            h.append(r)
            p._p.append(h)
        elif link:
            p.add_run(link[1] + ' (' + link[2] + ')')
        elif token.startswith('**'):
            p.add_run(token[2:-2]).bold = True
        elif token.startswith('`'):
            r = p.add_run(token[1:-1])
            r.font.name = 'Liberation Mono'
            r.font.size = Pt(9)
        else:
            p.add_run(token)


def table(lines):
    rows = [[v.strip() for v in line.strip().strip('|').split('|')] for line in lines]
    rows = [r for r in rows if not all(re.fullmatch(r'[-: ]+', v) for v in r)]
    n = len(rows[0])
    widths = {2: [2.4, 4.7], 3: [2.7, 2.2, 2.2],
              4: [1.2, 2.3, 1.8, 1.8],
              6: [.6, .65, 1.3, 1.35, .65, 2.55]}.get(n, [7.1 / n] * n)
    if rows[0][0] == 'Lab':
        widths = [.5, 4.2, 2.4]
    widths = [w * 7.1 / sum(widths) for w in widths]
    t = doc.add_table(rows=0, cols=n)
    t.autofit = False
    for c, w in zip(t.columns, widths):
        c.width = Inches(w)
    for i, row in enumerate(rows):
        cells = t.add_row().cells
        for cell, value, width in zip(cells, row, widths):
            cell.width = Inches(width)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(3)
            p.paragraph_format.space_after = Pt(3)
            inline(p, value)
            for r in p.runs:
                r.font.size = Pt(9)
                r.bold = i == 0
            pr = cell._tc.get_or_add_tcPr()
            borders = OxmlElement('w:tcBorders')
            for edge in ('top', 'left', 'bottom', 'right'):
                border = OxmlElement('w:' + edge)
                for key, v in [('val', 'single'), ('sz', '4'), ('color', 'D9D9D9')]:
                    border.set(qn('w:' + key), v)
                borders.append(border)
            pr.append(borders)
            if i == 0:
                shade = OxmlElement('w:shd')
                shade.set(qn('w:fill'), 'E7E6E6')
                pr.append(shade)
        props = t.rows[-1]._tr.get_or_add_trPr()
        props.append(OxmlElement('w:cantSplit'))
        if i == 0:
            props.append(OxmlElement('w:tblHeader'))
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def markdown(text, new_page=False):
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.strip() in ('<copy>', '</copy>'):
            i += 1
            continue
        if line.startswith('```'):
            block = []
            i += 1
            while i < len(lines) and not lines[i].startswith('```'):
                if lines[i].strip() not in ('<copy>', '</copy>'):
                    block.append(lines[i])
                i += 1
            p = doc.add_paragraph('\n'.join(block), style='Lab Code')
            p.paragraph_format.keep_together = len(block) <= 12
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                rows.append(lines[i])
                i += 1
            table(rows)
            continue
        elif line.startswith('!['):
            # SVG source diagrams remain in the HTML workshop; explain their
            # information directly in Word rather than add unrenderable assets.
            label = re.match(r'!\[([^]]+)\]', line)[1]
            p = doc.add_paragraph(label, style='Caption')
            p.paragraph_format.keep_with_next = True
            if 'flow' in label.lower():
                doc.add_paragraph('Streamlit or CLI → authenticated DDS end user → '
                                  'Autonomous Database data grants → authorized tool '
                                  'results → Select AI Agent with OCI Generative AI → AI response.')
            elif 'layout' in label.lower():
                doc.add_paragraph('The sidebar holds sign-in controls. The main area '
                                  'shows active identity, PDB, AI provider and prompt, followed '
                                  'by database tool results, raw JSON and the AI answer.')
        elif line.startswith('#'):
            level = len(line) - len(line.lstrip('#'))
            title = line[level:].strip()
            title = re.sub(r'^Task (\d+):', r'Task \1', title)
            title = re.sub(r'^Lab (\d+):', r'Lab \1', title)
            p = doc.add_heading(title, min(level, 3))
            if level == 1 and new_page:
                p.paragraph_format.page_break_before = True
        else:
            p = doc.add_paragraph()
            if line.startswith('- '):
                p.style = 'List Bullet'
                line = line[2:]
            elif re.match(r'^\d+\. ', line):
                # Preserve each task's explicit numbering; the built-in Word
                # list otherwise continues across unrelated labs and sections.
                p.paragraph_format.left_indent = Inches(.18)
                p.paragraph_format.first_line_indent = Inches(-.18)
            inline(p, line)
        i += 1


title = 'Oracle Autonomous Database 26ai Deep Data Security Live Lab'
doc.add_paragraph(title, style='Title')
doc.add_paragraph('Database setup Python AI agent and Streamlit interface', style='Subtitle')
doc.add_paragraph('Build and present an employee and manager demonstration in which '
                  'Oracle enforces row and column authorization before data reaches '
                  'OCI Generative AI through Select AI Agent. This guide includes setup, SQL tests, wallet '
                  'configuration, runnable Python and Streamlit code, expected results '
                  'and ADMIN-based cleanup.')
doc.add_paragraph('Audience  Database administrators developers and presenters')
doc.add_paragraph('Duration  About 150 minutes after prerequisites and downloads')
doc.add_paragraph('Updated  23 November 2026')
doc.add_heading('How to use this guide', 1)
doc.add_paragraph('Use the supplied ZIP or GitHub repository to run the files directly. '
                  'All commands assume the extracted project root. Replace ADB_LAB '
                  'with your actual wallet service alias. Set the SQL and Python '
                  'container guards to the real container name. Follow Labs 1 through '
                  '6, optionally Lab 7, and finish with Lab 8.')
doc.add_paragraph('The full source listings are included after the workshop tasks. '
                  'Preserve filenames, indentation and straight quotes if copying '
                  'them. Visual line wrapping does not add source line breaks.')

manifest = json.loads((root / 'workshops/livelabs/manifest.json').read_text())
doc.add_heading('Workshop navigation', 1)
for entry in manifest['tutorials']:
    doc.add_paragraph(entry['title'], style='List Bullet')
doc.add_paragraph('Source listings  SQL application tests and configuration', style='List Bullet')

for index, entry in enumerate(manifest['tutorials']):
    path = (root / 'workshops/livelabs' / entry['filename']).resolve()
    text = path.read_text()
    # Each task page is included; repetitive acknowledgement blocks remain in
    # Markdown, with the date and attribution retained once in the guide.
    text = text.split('## Acknowledgements')[0].rstrip()
    if 2 <= index <= 9:
        lines = text.splitlines()
        lines[0] = '# ' + entry['title']
        text = '\n'.join(lines)
    markdown(text, new_page=True)

doc.add_heading('Complete executable source listings', 1).paragraph_format.page_break_before = True
doc.add_paragraph('These listings are read directly from the released files. No '
                  'real connection values, wallets or credentials are included. '
                  'The compatibility SQL entry points call the canonical setup '
                  'scripts; execute only one setup pair.')
sources = []
groups = [
    ('SQL scripts', sorted((root / 'sql').glob('*.sql'))),
    ('Python agent and interface', sorted((root / 'agent').glob('*.py')) + [root / 'streamlit_app.py']),
    ('Offline application tests', sorted((root / 'tests').glob('*.py'))),
    ('Runtime configuration and launchers', [root / p for p in (
        'config.env.example', '.streamlit/config.toml', 'requirements.txt',
        'requirements-streamlit.txt', 'setup.sh')]),
]
for group, paths in groups:
    doc.add_heading(group, 2)
    for path in paths:
        name = path.relative_to(root).as_posix()
        p = doc.add_paragraph()
        p.paragraph_format.keep_with_next = True
        p.add_run(name).bold = True
        source = path.read_text().rstrip('\n')
        doc.add_paragraph(source, style='Lab Code')
        sources.append((name, source))

doc.add_heading('Acknowledgements', 1)
doc.add_paragraph('Prepared for Vivek Verma. Workshop structure follows the supplied '
                  'OCI Database Management sample and the Oracle LiveLabs task pattern. '
                  'This is a custom workshop, not a published Oracle LiveLabs catalog entry.')
header = section.header.paragraphs[0]
header.add_run('Autonomous Database 26ai  |  Deep Data Security live lab').font.size = Pt(9)
footer = section.footer.paragraphs[0]
footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
footer.add_run('23 November 2026  |  Page ').font.size = Pt(9)
field = OxmlElement('w:fldSimple')
field.set(qn('w:instr'), 'PAGE')
footer._p.append(field)
for element in (doc.styles.element, doc.element):
    for border in list(element.iter(qn('w:pBdr'))):
        border.getparent().remove(border)
doc.core_properties.title = title
doc.core_properties.subject = 'Autonomous Database end to end SQL Python and Streamlit workshop'
doc.core_properties.author = ''
doc.core_properties.last_modified_by = ''
output = root / 'docs/Oracle_26ai_Deep_Data_Security_End_to_End_LiveLab.docx'
output.parent.mkdir(exist_ok=True)
doc.save(output)
paragraphs = [p.text for p in Document(output).paragraphs]
for name, source in sources:
    assert source in paragraphs, 'Missing or altered source listing: ' + name
print(f'PASS: generated Word guide from 11 pages and {len(sources)} complete source listings: {output}')
