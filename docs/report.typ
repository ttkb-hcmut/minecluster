#import "/article": *
#let title2(name, desc) = {
  title[= #name: #(desc.body)]
}
#title2[Minecluster][= Minecraft server protocol with automatic host transfer]
This paper presents *Minecluster* #footnote[Source code is publicly available at https://github.com/ttkb-hcmut/minecluster].
// vi: set nowrap:
