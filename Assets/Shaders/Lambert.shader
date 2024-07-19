Shader "Custom/Lambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            struct appdata
            {
                float3 vertex : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWS : VAR_NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //顶点计算
                float3 positionWS = TransformObjectToWorld(v.vertex); //顶点：模型空间转世界空间
                o.vertex = TransformWorldToHClip(positionWS); //顶点：世界空间转齐次裁剪空间
                //法线计算
                o.normalWS = TransformObjectToWorldNormal(v.normalOS); //法线向量：模型空间转世界空间
                //UV坐标计算
                float4 mainTexST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainTex_ST);
                o.uv = v.uv * mainTexST.xy + mainTexST.zw; //纹理UV坐标：加上缩放和平移参数
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                //计算片元上主光照颜色
                half3 mainLightDir = half3(_MainLightPosition.xyz); //主光照方向
                half3 mainLightColor = _MainLightColor.rgb; //主光照颜色
                half NdotL = saturate(dot(i.normalWS, mainLightDir)); //片元上光照强度（通过点积计算光照向量投射到法线向量强度）
                half3 lightColor = mainLightColor * NdotL; //主光照颜色乘以强度，得到最终片元上光照颜色
                //通过颜色贴图，获得反照率颜色
                float4 col = tex2D(_MainTex, i.uv);
                //计算最终片元颜色
                return float4(col.rgb * lightColor, col.a);
            }
            ENDHLSL
        }
    }
}
