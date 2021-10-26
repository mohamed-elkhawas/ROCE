package types_def;

	parameter

		data_width  = 16, 	
		address_width = 30,
		read_entries  = 64,
		read_entries_log = 6,
		write_entries = 64,
		write_entries_log = 6,
		banks_no = 16,
		bank_group_no = 4,
		row_addres_len =16,

		t = 10 ;

  typedef enum logic {read , write} r_type;

  typedef struct packed {
	logic [1:0] bank_group ;
	logic [1:0] bank ;
	logic [15:0] row ;
	logic [9:0] column ;	

	} address_type;

  typedef struct packed {
	r_type req_type ;
	logic [data_width -1:0] data ;
	address_type address ;
  } request ;

  typedef struct packed {
	logic [15:0] row ;
	logic [9:0] column ;
	} opt_address_type;

  typedef struct packed {
	r_type req_type ;
	logic [data_width -1:0] data ;
	opt_address_type address ;
  } opt_request ;


  typedef enum logic [2:0] {activate , read_cmd , write_cmd  ,  precharge , none , refresh_all} command ;
  
  typedef enum logic [2:0] {started_filling , almost_done, full , empty , returning_data , waiting} burst_states_type ;

endpackage