Shader "Unlit/NewUnlitShader" {
    Properties {
        _Color ("Main Color", Color) = (0.5, 0.5, 1., 1)
    }
    SubShader {
        Pass {

        	CGPROGRAM
        	#include "UnityCG.cginc"
        	#pragma vertex vert
        	#pragma fragment frag
        	#pragma geometry geom
        	#pragma target 4.0

        	struct v2g {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR0;
            };

            struct g2f {
            	float4 pos : SV_POSITION;
            	fixed3 color : COLOR0;
            };

            v2g vert(appdata_base v) {
           		float3 v0 = v.vertex.xyz;
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            [maxvertexcount(58)]
            void geom(point v2g IN[1], inout TriangleStream<g2f> triStream) {
            	float3 v0 = IN[0].pos.xyz;
            	g2f OUT;
            	OUT.color = IN[0].color;

            	for (int i = 0; i < 20; i++) {
	            	OUT.pos = UnityObjectToClipPos(v0 + float3(1 * i, 0, 0));
	            	triStream.Append(OUT);
            	}
            	
            }


            fixed4 frag(g2f i) : SV_Target {
                return fixed4 (i.color, 1);
            }


        	ENDCG
        }
    }
}