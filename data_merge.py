import json
import os
import re

pattern = re.compile(r"/imageassets/(?P<key>[a-zA-Z0-9 ]+?)/")

"""
convert the CDN url to the persistane url, for example :
original url : http://cdn.pic-collage.com/expires_in_days/7/imageassets/3abd6f609ed8775b5bf508847ab772cb/182x273.jpg
we expect the persistance url like :
http://pic-collage.com/api/assets?key=55efef41df9987020de88401bcc96a49
"""
def convertUrl(url):
	if "imageassets" in url:
		return "http://pic-collage.com/api/assets?key={0}".format(pattern.search(url).group("key"))
	return url
# print convertUrl("http://cdn.pic-collage.com/expires_in_days/7/imageassets/3abd6f609ed8775b5bf508847ab772cb/182x273.jpg")
dict = {}
collageNum = 0
list = []
for f in os.listdir('data'):
	f = open('data/' + f, 'r')
	data = json.loads(f.read())
	collageNum = collageNum + len(data)
	for collage in data:
		path = collage['background_path']
		collage['url'] = convertUrl(collage['url'])
		list.append(collage)
		if path in dict:
			dict[path] = dict[path] + 1
		else:
			dict[path] = 1

print "collage list size " + str(collageNum)
print "background size = " + str(len(dict))
for d in dict:
	print d + " (" + str(dict[d]) + ")"

# output the result
# output = open('merged_feature_feed.json', 'w')
# output.write(json.dumps(list))

