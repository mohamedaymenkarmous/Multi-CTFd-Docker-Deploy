#!/usr/bin/python3

import ruamel.yaml
import sys
import collections

def mergeCommentedSeq(data,data1):
 if data and len(data)>0:
  for i in data:
    if i and i not in data1:
      data1.append(i)
 return data1

def parseYaml(data,data1):
 #print("data",data)
 if isinstance(data,str)==False:
  #print("data is not str",data,type(data))
  for i in data.keys():
    # Source node is a string
    if isinstance(data[i],str):
      #print("data[i] is str",i,data[i],type(data[i]))
      if i in data1:
        data1.update({i:data[i]})
      else:
        #print("data1[i] is str",i,data1,type(data1))
        data1=data
      #  data.update({i:merge(data1[i],data[i])})
      #else:
    # Source node is not a string
    elif data[i]!=None:
      #print("data[i] is not str",i,data[i],type(data[i]))
      if i in data1:
        #print("i in data1",type(data1[i]))
        # Destination node using the source key exists
        if data1[i] and isinstance(data1[i],ruamel.yaml.comments.CommentedSeq):
          #print("Comment",data1[i].ca)
          tmp=mergeCommentedSeq(data[i],data1[i])
          #print("merged",tmp)
          #print("data[i]",type(data[i]))
          if isinstance(data[i],ruamel.yaml.comments.CommentedMap):
            for j in data[i].ca.items:
              #print("comment of node",j,(data[i].ca.items[j][2].value.strip()=="#Removed"))
              if data[i].ca.items[j][2].value.strip()=="#Removed" and j in data1[i]:
                del data1[i][j]
          data1[i]=list(tmp)
          #print("new data1[i]",data1[i],type(data1[i]))
        # Destination node using the source key does not exists and source node value is different to the destination node value (even for None value)
        elif data1[i]!=data[i]:
          #print(",data[i]",type(data[i]))
          if isinstance(data[i],ruamel.yaml.comments.CommentedMap):
            for j in data[i].ca.items:
              #print("comment of node2",j,(data[i].ca.items[j][2].value.strip()=="#Removed"))
              if data[i].ca.items[j][2].value.strip()=="#Removed" and j in data1[i]:
                del data1[i][j]
          #print("Parsing",data[i],data1[i],type(data1[i]))
          data1.update({i:parseYaml(data[i],data1[i])})
      else:
        #print("i not in data1")
        data1[i]=data[i]
    #else:
    #  del data1[i]
 #print("final data1",data1)
 #yaml=ruamel.yaml.YAML(typ='rt')
 #yaml.dump(data1, sys.stdout)
 return data1

def main():
  yaml = ruamel.yaml.YAML(typ='rt')
  #yaml.default_flow_style = None
  yaml.indent(mapping=2, sequence=1, offset=2)
  yaml.compact(seq_seq=False, seq_map=False)
  #Load the yaml files
  with open(sys.argv[1]) as fp:
    data = yaml.load(fp)
  with open(sys.argv[2]) as fp:
    data1 = yaml.load(fp)
  #print(data1.keys())
  #Add the resources from test2.yaml to test1.yaml resources
  data2=parseYaml(data,data1)
  #yaml.dump(data2, sys.stdout)
  #create a new file with merged yaml
  yaml.dump(data2, open(sys.argv[3], 'w'))

if __name__ == '__main__':
  if len(sys.argv)==4:
    main()
  else:
    print("Syntax: "+sys.argv[0]+" yaml_file_input_1 yaml_file_input_2 yaml_file_output")
