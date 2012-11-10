# tmp.py
import re;
file = open('tmp.txt', 'r');
out = open('out.txt', 'w');

data = file.read();
rule = r'([^,]+)=>([^,]+)';
reg = re.compile(rule);

match = reg.findall(data);

for m in match:
	out.write('%s=>%s' % (m[1], m[0]) + ','),
