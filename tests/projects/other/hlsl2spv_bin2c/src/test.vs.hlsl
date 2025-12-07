struct VSInput {
    float3 position : POSITION;
    float2 texcoord : TEXCOORD0;
};

struct VSOutput {
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD0;
};

VSOutput main(VSInput input) {
    VSOutput output;
    output.position = float4(input.position, 1.0);
    output.texcoord = input.texcoord;
    return output;
}

