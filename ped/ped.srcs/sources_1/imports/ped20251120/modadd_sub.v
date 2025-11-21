module modadd_sub (

    input          field,

    input  [252:0] in0,

    input  [252:0] in1,

    input          func,

    output [252:0] out

);





    localparam edward_P = 253'h12ab655e9a2ca556_60b44d1e5c37b001_59aa76fed0000001_0a11800000000001;



    wire [254:0] add_temp_s0;

    wire [254:0] add_temp_s1;

    wire [254:0] add_temp_s2;

    wire [254:0] add_temp_s3;



    wire [253:0] sub_temp_s0;

    wire [253:0] sub_temp_s1;

    wire [253:0] sub_temp_s2;



    wire [252:0] add_rslt;

    wire [252:0] sub_rslt;



    assign add_temp_s0 = in0 + in1;

    assign add_temp_s1 = add_temp_s0 - edward_P;

    assign add_temp_s2 = add_temp_s1 - edward_P;

    assign add_temp_s3 = add_temp_s2 - edward_P;



    assign sub_temp_s0 = field ? {1'b0, in0} - {1'b0, in1} : {in0[252], in0} - {in1[252], in1};

    assign sub_temp_s1 = sub_temp_s0 + edward_P;

    assign sub_temp_s2 = sub_temp_s1 + edward_P;



    assign add_rslt = (add_temp_s3[254:253] == 2'b00) ? add_temp_s3[252:0]:

                    (add_temp_s2[254:253] == 2'b00) ? add_temp_s2[252:0]:

                    (add_temp_s1[254:253] == 2'b00) ? add_temp_s1[252:0]:

                                            add_temp_s0[252:0];

    assign sub_rslt = (~sub_temp_s0[253]) ? sub_temp_s0[252:0]:

                    (~sub_temp_s1[253]) ? sub_temp_s1[252:0]:

                                            sub_temp_s2[252:0];



    assign out = func ? sub_rslt : add_rslt;



endmodule



