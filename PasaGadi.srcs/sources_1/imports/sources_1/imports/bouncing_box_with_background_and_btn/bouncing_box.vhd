-- Listing 13.3
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity bouncing_box is
   port(
      clk, reset: in std_logic;
      BTNL, BTNR, BTNU, BTND: in std_logic;
      -- VGA display
      hsync, vsync: out std_logic;
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
   -- spaceship
   signal dir_x, dir_y : integer := 1;  
   signal x, y, next_x, next_y : integer := 0;       
   signal car_xl, car_yt, car_xr, car_yb : integer := 0;
   -- box
   signal dir_x2, dir_y2, inccc : integer := 1;
   signal x2, y2, next_x2, next_y2 : integer := 0;
   signal box_xl, box_yt, box_xr, box_yb : integer := 0;
   
   -- tracks
   --signal track_l1, track_l2, track_r1, track_r2 : integer := 0;
   
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
--    track_l1 <= 100;
--    track_l2 <= 105;
--    track_r1 <= 500;
--    track_r2 <= 505;
      
    -- CAR position
    car_xl <= x;  
    car_yt <= y;
    car_xr <= x + 60;
    car_yb <= y + 60;  
    
    -- box position
    box_xl <= x2;  
    box_yt <= y2;
    box_xr <= x2 + 20;
    box_yb <= y2 + 20;  
    
    -- process to generate update position signal
    process ( video_on )
        variable counter : integer := 0;
    begin
        if rising_edge(video_on) then
            counter := counter + 1;
            if counter > 120 then                           -- INCREASE COUNTER TO SLOW DOWN THE PROGRAM
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
	-- X DIRECTION CALCULATIONS
	process ( btn_r, btn_l, dir_x, clk, car_xr, car_xl, car_yt, car_yb, dir_x2,box_xl,box_xr,box_yt,box_yb)
	begin
        if rising_edge(clk) then 
            
		    if (car_xr > 639) and (dir_x = 1) then
                dir_x <= -1;
				x <= 579;				
            elsif (car_xl < 1) and (dir_x = -1) then
                dir_x <= 1;   
				x <= 0;				
            elsif ( btn_r = '1' ) then 
                dir_x <= 1;
				x <= next_x;
            elsif ( btn_l = '1' ) then
                dir_x <= -1;
				x <= next_x;
		    else 
				dir_x <= 0;
				x <= next_x;
            end if;
            -- alien x position
            if (box_xr > 639) and (dir_x2 >= 1) then
                dir_x2 <= -1;
                x2 <= 619;                
            elsif (box_xl < 1) and (dir_x2 <= -1) then
                dir_x2 <= 1;   
                x2 <= 0;                
            else 
                dir_x2 <= dir_x2;
                x2 <= next_x2;
            end if;
		end if;
	end process;
	
	-- compute collision in y or change direction if btn_u or btn_d is pressed
	-- Y DIRECTION CALCULATIONS
	process ( btn_u, btn_d, dir_y, clk, car_xr, car_xl, car_yt, car_yb, dir_y2,box_xl,box_xr,box_yt,box_yb)
	begin
        if rising_edge(clk) then 
                
		    if (car_yb > 479) and (dir_y = 1) then
                dir_y <= -1;
                y <= 459;
            elsif (car_yt < 1) and (dir_y = -1) then
                dir_y <= 1;   
                y <= 0; 	
            elsif ( btn_u = '1' ) then 
                dir_y <= -1;
				y <= next_y;
            elsif ( btn_d = '1' ) then 
                dir_y <= 1;
				y <= next_y;
		    else 
				dir_y <= 0;
				y <= next_y;
            end if;
            --alien y position
            if (box_yb > 479) and (dir_y2 >= 1) then
                dir_y2 <= -1;
                y2 <= 419;
            elsif (box_yt < 1) and (dir_y2 <= -1) then
                dir_y2 <= 1;   
                y2 <= 0;     
            else 
                dir_y2 <= dir_y2;
                y2 <= next_y2;
            end if;
		end if;
	end process;	
	
    -- compute the next x,y position of box 
    process ( update_pos, x, y, x2, y2 )
    begin
        if rising_edge(update_pos) then 
			next_x <= x + dir_x;
			next_y <= y + dir_y;
			next_x2 <= x2 + dir_x2;
			next_y2 <= y2 + dir_y2;
			inccc <= inccc + 1;
		end if;
    end process;
    
    
    
    
    -- DRAW STUFF
    -- process to generate next colors           
    process (pixel_x, pixel_y)
    begin
           -- white tracks
--           if (unsigned(pixel_x) >= track_l1) and (unsigned(pixel_x) <= track_l2) then
--               red_next<="1111"; green_next<="1111"; blue_next<="1111";
--           elsif (unsigned(pixel_x) >= track_r1) and (unsigned(pixel_x) <= track_r2) then
--               red_next<="1111"; green_next<="1111"; blue_next<="1111";


           -- DRAW SPACESHIP
           if (unsigned(pixel_x) > car_xl) and (unsigned(pixel_x) < car_xr) and
           (unsigned(pixel_y) > car_yt) and (unsigned(pixel_y) < car_yb) then
               red_next <= "0000";
               green_next <= "1111";
               blue_next <= "1111"; 
               
           -- DRAW ALIEN
           elsif (unsigned(pixel_x) > box_xl) and (unsigned(pixel_x) < box_xr) and
           (unsigned(pixel_y) > box_yt) and (unsigned(pixel_y) < box_yb) then
               red_next <= "1111";
               green_next <= "0000";
               blue_next <= "0000";

           -- DRAW (hardcoded) STARS
           elsif (unsigned(pixel_x) >= 50) and (unsigned(pixel_x) <= 52) and (unsigned(pixel_y) >= 100) and (unsigned(pixel_y) <= 102) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= 160) and (unsigned(pixel_x) <= 162) and (unsigned(pixel_y) >= 60) and (unsigned(pixel_y) <= 62) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= 90) and (unsigned(pixel_x) <= 92) and (unsigned(pixel_y) >= 320) and (unsigned(pixel_y) <= 322) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= 350) and (unsigned(pixel_x) <= 352) and (unsigned(pixel_y) >= 260) and (unsigned(pixel_y) <= 262) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= 440) and (unsigned(pixel_x) <= 442) and (unsigned(pixel_y) >= 70) and (unsigned(pixel_y) <= 72) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= 552) and (unsigned(pixel_x) <= 554) and (unsigned(pixel_y) >= 120) and (unsigned(pixel_y) <= 122) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           elsif (unsigned(pixel_x) >= 530) and (unsigned(pixel_x) <= 532) and (unsigned(pixel_y) >= 450) and (unsigned(pixel_y) <= 452) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";       
           elsif (unsigned(pixel_x) >= 210) and (unsigned(pixel_x) <= 212) and (unsigned(pixel_y) >= 330) and (unsigned(pixel_y) <= 332) then
               red_next<="1111"; green_next<="1111"; blue_next<="1111";
           
           -- DRAW BACKGROUND
           else    
               -- background color grey
               red_next <= "0000";
               green_next <= "0000";
               blue_next <= "0000";
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