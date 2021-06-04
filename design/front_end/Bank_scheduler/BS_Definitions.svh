
/*
	request format---> request type bit + index bits + address bits + data (if write request).
*/

 

`define READ  1'b0
`define WRITE 1'b1


// size of request
`define VALID_BIT		1
`define ROW_BITS        16
`define COL_BITS        14
`define ADDR_BITS       `ROW_BITS+`COL_BITS
`define INDEX_BITS      6
`define TYPE_BIT		1
`define DATA_BITS       7
`define REQUEST_SIZE	`VALID_BIT+`ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS // valid + address + index + request type+ data bits 
`define BURST_BITS		4 ///just to detect burst --> not an additional bits to request

//positions of bits
`define TYPE_POS    7
`define VALID_POS  24
`define ADDR_POS   16
`define BURST_POS  20
`define ROW_POS    10
`define COL_POS    26      




