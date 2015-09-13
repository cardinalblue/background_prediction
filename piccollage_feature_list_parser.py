import urllib2
import json

bgprefix = "bundled:/backgrounds/"
def parseBackgroundPath(struct):
	for s in struct['scraps']:
		if 'is_background' in s and s['is_background']:
			path = s['image']['source_url']
			if path.startswith(bgprefix):
				return path[len(bgprefix):]

featureFeedUrl = "http://pic-collage.com/api/collages/feed?includes=struct&limit={0}&offset={1}"
limit = 20
def queryData(offset):
	url = featureFeedUrl.format(limit, offset)
	print url
	req = urllib2.Request(url)
	resp = urllib2.urlopen(req)
	j = json.loads(resp.read())
	result = []
	for d in j['collages']['data']:
		path = parseBackgroundPath(d['struct'])
		if path is not None:
			result.append({
				'background_path': path,
				'id': d['id'],
				'url': d['image_thumb']
			})
	return result

start = 4000
step = 10
output = []
f = open("data/lm_bg_{0}_{1}.json".format(start, start + (limit * step)), 'w')
for i in range(step):
	output = output + queryData(start + (i * limit))
f.write(json.dumps(output))
f.close()