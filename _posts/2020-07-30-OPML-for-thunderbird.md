---
layout: post
title:  "OPML for thunderbird"
comments: true
---

Well, silly me. I forgot to backup the postgres for miniflux, and the miniflux is gone for me.
On the good side, I backup the `feeds.opml` every day, so I just need to migrate to something 
else. Now that I move to thunderbird as my default mail/nntp reader, why not just add some RSS too.

To my surprise, thunderbird understands opml file a bit different. When you add a feed manually,
you will get:

```xml
<outline title="same as feed">
    <outline title="same as feed" text="same as title usually" xmlUrl="https://url-to-rss-or-atom" htmlUrl="https://url-to-website" type="rss" version="RSS"/>
</outline>
```

The wrapping outline is required, otherwise, you cannot see each feed individually. 
Moreover, `type` and `version` are required too, otherwise, thunderbird treats this
outline as a simple folder. (`fz:` options are private to thunderbird, they are optional for new feeds)

Well, let's roll out a short script to fix that:

```go
// PUBLIC DOMAIN
package main

import (
	"os"

	"github.com/beevik/etree"
)

func newDoc() (chan *etree.Element, chan struct{}) {
	input := make(chan *etree.Element, 1)
	done := make(chan struct{})

	go func() {
		doc := etree.NewDocument()
		doc.CreateProcInst("xml", `version="1.0" encoding="UTF-8"`)
		doc.Indent(2)

		opml := doc.CreateElement("opml")
		opml.CreateAttr("version", "2.0")

		root := opml.CreateElement("body").CreateElement("outline")
		root.CreateAttr("title", "All")

		for {
			lastSeen := false
			select {
			case elem := <-input:
				if elem == nil {
					doc.WriteTo(os.Stdout)
					lastSeen = true
					break
				}
				folder := root.CreateElement("outline")
				folder.CreateAttr("title", elem.SelectAttrValue("title", ""))
				feed := elem.Copy()
				feed.CreateAttr("version", "RSS")
				feed.CreateAttr("type", "rss")
				//feed.CreateAttr("fz:quickMode", "false")
				//feed.CreateAttr("fz:options", `{"version":2,"updates":{"enabled":true,"updateMinutes":1440,"updateUnits":"min"},"category":{"enabled":false,"prefixEnabled":false,"prefix":""}}`)
				folder.AddChild(feed)
			}
			if lastSeen {
				break
			}
		}

		close(done)
	}()

	return input, done
}

func main() {
	output, done := newDoc()
	doc := etree.NewDocument()
	if err := doc.ReadFromFile(os.Args[1]); err != nil {
		panic(err)
	}

	root := doc.SelectElement("opml").SelectElement("body")

	for _, elem := range root.SelectElements("outline") {
		output <- elem
	}

	output <- nil

	<-done
}
```
