import sys, requests, jinja2

temp = requests.get("https://raw.githubusercontent.com/andasa-de/CloudInit/master/initd.j2").content
template = jinja2.Template(temp)
print template.render(component=sys.argv[1], components_path=sys.argv[2], project=sys.argv[3])

