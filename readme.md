
dotbpe
-------------
dotbpe是一款基于CSharp编写的RPC框架，但是它的目标不仅仅只是解决rpc的问题，而是解决整个业务解决方案的问题，封装在常见的项目产品开发中的通用组件，让开发人员只专注于开发业务逻辑代码。底层通信默认实现基于DotNetty，可替换成其他Socket通信组件。dotbpe使用的默认协议名称叫Amp,编解码使用谷歌的Protobuf3,不过这些默认实现都是可以替换的。





### 快速开始

#### 1.  定义使用Protobuf来定义服务描述文件 

```protobuf
//dotbpe_option.proto
// [START declaration]
syntax = "proto3";
package dotbpe;
// [END declaration]

// [START csharp_declaration]
option csharp_namespace = "DotBPE.ProtoBuf";
// [END csharp_declaration]

import "google/protobuf/descriptor.proto";

//扩展服务
extend google.protobuf.ServiceOptions {
  int32 service_id = 51001;
  bool disable_generic_service_client = 51003; //是否生成客户端代码
  bool disable_generic_service_server = 51004; //是否生成服务端代码
}
extend google.protobuf.MethodOptions {
  int32 message_id = 51002;
}

extend google.protobuf.FileOptions {
  bool disable_generic_services_client = 51003; //是否生成客户端代码
  bool disable_generic_services_server = 51004; //是否生成服务端代码
  bool generic_markdown_doc = 51005; //是否生成文档
}

```



```protobuf
//HelloRpc.proto
syntax = "proto3";
package dotbpe;

option csharp_namespace = "HelloRpc.Common";

import public "dotbpe_option.proto";

service Greeter {
  option (service_id)= 100 ;//设定服务ID
  // Sends a greeting
  rpc Hello (HelloRequest) returns (HelloResponse) {
    option (message_id)= 1 ;//设定消息ID
  }

}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}
// The response message containing the greetings
message HelloResponse {
  string message = 1;
}
```



使用protoc 命令行+`dotbpe_amp.exe`插件来生成代码

```shell
set -ex

cd $(dirname $0)/../../sample/HelloRpc/

PROTOC=protoc
PLUGIN=protoc-gen-dotbpe=../../tool/ampplugin/dotbpe_amp.exe
HELLORPC_DIR=./HelloRpc.Common/
PROTO_DIR=../../protos

$PROTOC  -I=$PROTO_DIR --csharp_out=$IntegrationTesting_DIR --dotbpe_out=$HELLORPC_DIR \
    $PROTO_DIR/{dotbpe_option,hell_rpc}.proto  --plugin=$PLUGIN
```

#### 2. 编写服务端代码

```C#

using System;
using DotBPE.Protocol.Amp;
using DotBPE.Rpc.Netty;
using System.Threading.Tasks;
using DotBPE.Rpc.Client;
using DotBPE.Rpc.Extensions;
using DotBPE.Rpc.Hosting;
using HelloRpc.Common;
using Microsoft.Extensions.Configuration;

namespace HelloRpc.Server
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;


            var host = new RpcHostBuilder()
                .AddRpcCore<AmpMessage>() //添加核心依赖
                .UseNettyServer<AmpMessage>()  //使用使用Netty默认实现
                .UseAmp() //使用Amp协议中的默认实现
                .AddServiceActors(actors =>
                {
                    actors.Add<GreeterImpl>();
                }) //注册服务
                .Build();

            host.StartAsync().Wait();

            Console.WriteLine("Rpc Server is Started....,Default Port:6201");
            Console.ReadKey();

            host.ShutdownAsync().Wait();

        }
    }

    public class GreeterImpl : GreeterBase //实现真实的逻辑
    {        
        public override Task<HelloResponse> HelloAsync(HelloRequest request)
        {
            return Task.FromResult(new HelloResponse() { Message = "Hello " + request.Name });
        }
    }

}

```



#### 3. 编写客户端类

````C#
using System;
using System.Text;
using System.Threading.Tasks;
using DotBPE.Protocol.Amp;
using DotBPE.Rpc;
using DotBPE.Rpc.Codes;
using DotBPE.Rpc.Extensions;
using DotBPE.Rpc.Netty;
using Microsoft.Extensions.DependencyInjection;
using HelloRpc.Common;

namespace HelloRpc.Client
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;

            var client = AmpClient.Create("127.0.0.1:6201");
            var greeter = new GreeterClient(client);
           
           Console.WriteLine("请输入你的名称");
           string name = Console.ReadLine();
          
          try
          {
            var reply = greeter.HelloAsync(new HelloRequest(){Name = name}).Result;
            Console.WriteLine($"---------------收到服务端返回:{reply.Message}-----------");
          }
          catch(Exception ex){
          	Console.WriteLine("发生错误："+ex.Message);
          }            
        }
    }
}

````



