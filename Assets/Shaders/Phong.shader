Shader "Custom/Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularColor("SpecularColor",Color) = (1,1,1,1) // 镜面反射颜色属性
        _Gloss("Gloss",Range(1,256)) = 5// 镜面反射系数
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

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
                float3 positionWS : VAR_POSITION;
                half3 normalWS : VAR_NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _SpecularColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _Gloss)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            //环境光：通过球谐光照参数和法线向量计算
            half3 AmbientLight(half3 normalWS)
            {
                float4 coefficients[7];
                coefficients[0] = unity_SHAr;
                coefficients[1] = unity_SHAg;
                coefficients[2] = unity_SHAb;
                coefficients[3] = unity_SHBr;
                coefficients[4] = unity_SHBg;
                coefficients[5] = unity_SHBb;
                coefficients[6] = unity_SHC;
                return max(0.0, SampleSH9(coefficients, normalWS));
            }

            //漫反射：通过主光照方向向量、颜色和法线向量计算
            half3 DiffuseLight(half3 normalWS)
            {
                half3 mainLightDir = half3(_MainLightPosition.xyz); //主光照方向
                half3 mainLightColor = _MainLightColor.rgb; //主光照颜色
                half NdotL = saturate(dot(normalWS, mainLightDir)); //片元上光照强度（通过点积计算光照向量投射到法线向量强度）
                return mainLightColor * NdotL; //最终片元上漫反射光照
            }

            //镜面反射：通过主光照方向向量，颜色和视角向量、法线向以及镜面反射系数量计算
            half3 SpecularLight(half3 normalWS, float3 positionWS)
            {
                half3 mainLightDir = half3(_MainLightPosition.xyz); //主光照方向
                half3 mainLightColor = _MainLightColor.rgb; //主光照颜色
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS); //视角向量
                half3 reflectDir = normalize(reflect(-mainLightDir, normalWS)); //计算反射方向
                float gloss = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Gloss);
                float4 specularColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularColor);
                half3 specular = mainLightColor * specularColor.rgb * pow(saturate(dot(reflectDir, viewDirWS)), gloss); //计算最终镜面反射
                return specular;
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //顶点计算
                o.positionWS = TransformObjectToWorld(v.vertex); //顶点：模型空间转世界空间
                o.vertex = TransformWorldToHClip(o.positionWS); //顶点：世界空间转齐次裁剪空间
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
                //环境光
                half3 ambient = AmbientLight(i.normalWS);
                //漫反射
                half3 diffuse = DiffuseLight(i.normalWS);
                //镜面反射
                half3 specular = SpecularLight(i.normalWS, i.positionWS);
                //通过颜色贴图，获得反照率颜色
                float4 col = tex2D(_MainTex, i.uv);
                //计算最终片元颜色
                return float4((ambient + diffuse + specular)*col.rgb, col.a);
            }

            ENDHLSL
        }
    }
}
