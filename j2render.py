import sys, requests, jinja2

url = sys.argv[1]
variables = dict(map(lambda x: x.lstrip('-').split('='),sys.argv[2:]))
template = jinja2.Template(requests.get(url).content)
print template.render(variables)

