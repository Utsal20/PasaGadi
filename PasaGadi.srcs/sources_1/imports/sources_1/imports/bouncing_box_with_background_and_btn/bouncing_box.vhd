-- Listing 13.3
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity bouncing_box is
   port(
      clk, reset, BTNL, BTNR, BTNU, BTND: in std_logic;
      hsync, vsync: out  std_logic;
      red: out std_logic_vector(3 downto 0);
      green: out std_logic_vector(3 downto 0);
      blue: out std_logic_vector(3 downto 0)           
   );
end bouncing_box;

architecture bouncing_box of bouncing_box is
   signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
   signal video_on, pixel_tick: std_logic;
   signal red_reg, red_next: std_logic_vector(3 downto 0) := (others => '0');
   signal green_reg, green_next: std_logic_vector(3 downto 0) := (others => '0');
   signal blue_reg, blue_next: std_logic_vector(3 downto 0) := (others => '0'); 
   signal btn_l, btn_r, btn_u, btn_d: std_logic;  -- synchronized buttons
   signal dir_x, dir_y : integer := 1;  
   signal x, y, next_x, next_y : integer := 0;       
   signal box_xl, box_yt, box_xr, box_yb : integer := 0; 
   signal track_l1, track_l2, track_r1, track_r2 : integer := 0;
   signal update_pos : std_logic := '0';  
begin
   -- instantiate VGA sync circuit
   vga_sync_unit: entity work.vga_sync
    port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               p_tick=>pixel_tick);
               
    -- synchronize input buttons
    sync_l: entity work.synchronizer port map( clk=>clk, a=>BTNL, b=>btn_l );
    sync_r: entity work.synchronizer port map( clk=>clk, a=>BTNR, b=>btn_r );
    sync_u: entity work.synchronizer port map( clk=>clk, a=>BTNU, b=>btn_u );
    sync_d: entity work.synchronizer port map( clk=>clk, a=>BTND, b=>btn_d );          
    
    -- TRACK POSITION
    track_l1 <= 50;
    track_l2 <= 55;
    track_r1 <= 500;
    track_r2 <= 505;
      
               
    -- box position
    box_xl <= x;  
    box_yt <= y;
    box_xr <= x + 100;
    box_yb <= y + 100;  
    
    -- process to generate update position signal
    process ( video_on )
        variable counter : integer := 0;
    begin
        if rising_edge(video_on) then
            counter := counter + 1;
            if counter > 120 then
                counter := 0;
                update_pos <= '1';
            else
                update_pos <= '0';
            end if;
         end if;
    end process;

	
	-- the MUX that computes the next value of x. Anything that can affect
	-- x must be computed within this mux since a signal can only have one driver
	-- compute collision in x or change direction if btn_r or btn_l is pressed
	process ( btn_r, btn_l, dir_x, clk, box_xr, box_xl, box_yt, box_yb)
	begin
        if rising_edge(clk) then 
		    if (box_xr > 639) and (dir_x = 1) then
                dir_x <= -1;
				x <= 539;				
            elsif (box_xl < 1) and (dir_x = -1) then
                dir_x <= 1;   
				x <= 0;				
            elsif ( btn_r = '1' ) then 
                dir_x <= 1;
				x <= next_x;
            elsif ( btn_l = '1' ) then 
                dir_x <= -1;
				x <= next_x;
		    else 
				dir_x <= dir_x;
				x <= next_x;
            end if;
		end if;
	end process;
	
	-- compute collision in y or change direction if btn_u or btn_d is pressed
	process ( btn_u, btn_d, dir_y, clk, box_xr, box_xl, box_yt, box_yb)
	begin
        if rising_edge(clk) then 
		    if (box_yb > 479) and (dir_y = 1) then
                dir_y <= -1;
                y <= 379;
            elsif (box_yt < 1) and (dir_y = -1) then
                dir_y <= 1;   
                y <= 0; 	
            elsif ( btn_u = '1' ) then 
                dir_y <= -1;
				y <= next_y;
            elsif ( btn_d = '1' ) then 
                dir_y <= 1;
				y <= next_y;
		    else 
				dir_y <= dir_y;
				y <= next_y;
            end if;
		end if;
	end process;	
	
    -- compute the next x,y position of box 
    process ( update_pos, x, y )
    begin
        if rising_edge(update_pos) then 
			next_x <= x + dir_x;
			next_y <= y + dir_y;
		end if;
    end process;
    
    
    
    
    -- DRAW TRACK AND CAR
    -- process to generate next colors           
    process (pixel_x, pixel_y)
    begin
           if (unsigned(pixel_x) >= track_l1) and (unsigned(pixel_x) <= track_l2) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= track_r1) and (unsigned(pixel_x) <= track_r2) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
               
           elsif (unsigned(pixel_x) > box_xl) and (unsigned(pixel_x) < box_xr) and
           (unsigned(pixel_y) > box_yt) and (unsigned(pixel_y) < box_yb) then
               -- foreground box color yellow
               red_next <= "1111";
               green_next <= "1111";
               blue_next <= "0000"; 
           else    
               -- background color blue
               red_next <= "0000";
               green_next <= "0000";
               blue_next <= "1111";
           end if;   
    end process;








   -- generate r,g,b registers
   process ( video_on, pixel_tick, red_next, green_next, blue_next)
   begin
      if rising_edge(pixel_tick) then
          if (video_on = '1') then
            red_reg <= red_next;
            green_reg <= green_next;
            blue_reg <= blue_next;   
          else
            red_reg <= "0000";
            green_reg <= "0000";
            blue_reg <= "0000";                    
          end if;
      end if;
   end process;
   
   red <= STD_LOGIC_VECTOR(red_reg);
   green <= STD_LOGIC_VECTOR(green_reg); 
   blue <= STD_LOGIC_VECTOR(blue_reg);
     
end bouncing_box;