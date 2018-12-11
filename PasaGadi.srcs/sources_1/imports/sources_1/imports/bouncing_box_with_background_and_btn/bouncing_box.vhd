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
      blue: out std_logic_vector(3 downto 0);
      -- 7 seg
      SW : in STD_LOGIC_VECTOR(15 downto 0);
      AN : out STD_LOGIC_VECTOR(7 downto 0);
      CT : out STD_LOGIC_VECTOR(6 downto 0);
      DP : out STD_LOGIC;
      LED : out  STD_LOGIC_VECTOR(3 downto 0)
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
   signal x, y : integer := 500;
   signal next_x, next_y : integer := 500;       
   signal car_xl, car_yt, car_xr, car_yb : integer := 0;
   signal sp_size : integer := 40;
   -- alien 1
   signal dir_x2, dir_y2 : integer := 1;
   signal x2, y2, next_x2, next_y2 : integer := 0;
   signal alien_xl, alien_yt, alien_xr, alien_yb : integer := 0;
   signal al_size : integer := 20;
   -- alien 3
   signal dir_x3, dir_y3 : integer := 2;
   signal x3, y3, next_x3, next_y3 : integer := 0;
   signal alien3_xl, alien3_yt, alien3_xr, alien3_yb : integer := 0;
   signal al3_size : integer := 14;
   -- score
   signal score : integer := 0;
   signal switchesss : std_logic_vector(15 downto 0);
   
   signal gameover : integer := 0;
   
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
    
    -- 7 seg display
    seg: entity work.x7seg_top port map ( CLK100MHZ=>clk, SW=>switchesss, AN=>AN, CT=>CT, DP=>DP, LED=>LED );
      
      
    -- CAR position
    car_xl <= x;  
    car_yt <= y;
    car_xr <= x + sp_size;
    car_yb <= y + sp_size;  
    -- alien1 position
    alien_xl <= x2;  
    alien_yt <= y2;
    alien_xr <= x2 + al_size;
    alien_yb <= y2 + al_size; 
    -- alien3 position
    alien3_xl <= x3;  
    alien3_yt <= y3;
    alien3_xr <= x3 + al3_size;
    alien3_yb <= y3 + al3_size;
    
    -- 7-seg score display
    switchesss <= std_logic_vector(to_signed(score, switchesss'length));            -- https://www.nandland.com/vhdl/tips/tip-convert-numeric-std-logic-vector-to-integer.html
    
    
    
    
    -- process to generate update position signal
    process ( video_on )
        variable counter : integer := 0;
        variable scorecounter : integer := 0;
    begin
        if rising_edge(video_on) then
            counter := counter + 1;
            scorecounter := scorecounter + 1;
            if (counter > 120) and (gameover=0) then                           -- INCREASE COUNTER TO SLOW DOWN THE PROGRAM ?????
                counter := 0;
                update_pos <= '1';
            else
                update_pos <= '0';
            end if;
            
            if (scorecounter > 1000) and (gameover=0) then
                scorecounter := 0;
                score <= score + 1;
                switchesss <= std_logic_vector(to_signed(score, switchesss'length));
            end if;
         end if;
    end process;

	
	
	
	-- the MUX that computes the next value of x. Anything that can affect
	-- x must be computed within this mux since a signal can only have one driver

	-- X DIRECTION CALCULATIONS
	process ( btn_r,btn_l,clk , dir_x,car_xr,car_xl,car_yt,car_yb , dir_x2,alien_xl,alien_xr,alien_yt,alien_yb , dir_x3,alien3_xl,alien3_xr,alien3_yt,alien3_yb )
	begin
        if rising_edge(clk) then 
            -- spaceship movement
		    if (car_xr > 639) and (dir_x = 1) then
                dir_x <= -1;
				x <= 639 - sp_size;				
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
            if (alien_xr > 639) and (dir_x2 >= 1) then
                dir_x2 <= -1;
                x2 <= 639 - al_size;                
            elsif (alien_xl < 1) and (dir_x2 <= -1) then
                dir_x2 <= 0+1;   
                x2 <= 0;                
            else 
                dir_x2 <= dir_x2;
                x2 <= next_x2;
            end if;
            -- alien3 x position
            if (alien3_xr > 639) and (dir_x3 >= 2) then
                dir_x3 <= -2;
                x3 <= 639 - al3_size;                
            elsif (alien3_xl < 1) and (dir_x3 <= -2) then
                dir_x3 <= 0+2;   
                x3 <= 0;                
            else 
                dir_x3 <= dir_x3;
                x3 <= next_x3;
            end if;
		end if;
	end process;
	


	-- Y DIRECTION CALCULATIONS
	process ( btn_u,btn_d,clk , dir_y,car_xr,car_xl,car_yt,car_yb , dir_y2,alien_xl,alien_xr,alien_yt,alien_yb , dir_y3,alien3_xl,alien3_xr,alien3_yt,alien3_yb )
	begin
        if rising_edge(clk) then 
            -- spaceship y movement
		    if (car_yb > 479) and (dir_y = 1) then
                dir_y <= -1;
                y <= 479 - sp_size;
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
            if (alien_yb > 479) and (dir_y2 >= 1) then
                dir_y2 <= 0-1;
                y2 <= 479 - al_size;
            elsif (alien_yt < 1) and (dir_y2 <= -1) then
                dir_y2 <= 0+1;   
                y2 <= 0;     
            else 
                dir_y2 <= dir_y2;
                y2 <= next_y2;
            end if;
            --alien3 y position
            if (alien3_yb > 479) and (dir_y3 >= 2) then
                dir_y3 <= 0-2;
                y3 <= 479 - al3_size;
            elsif (alien3_yt < 1) and (dir_y3 <= -2) then
                dir_y3 <= 0+2;   
                y3 <= 0;     
            else 
                dir_y3 <= dir_y3;
                y3 <= next_y3;
            end if;
		end if;
	end process;	
	
    -- compute the next x,y position of alien 
    process ( update_pos, x, y, x2, y2, x3, y3 )
    begin
        if rising_edge(update_pos) then 
			next_x <= x + dir_x;
			next_y <= y + dir_y;
			next_x2 <= x2 + dir_x2;
			next_y2 <= y2 + dir_y2;
			next_x3 <= x3 + dir_x3;
			next_y3 <= y3 + dir_y3;
		end if;
    end process;
    
    
    -- COLLISION CHECKS
    process ( car_xr,car_xl,car_yt,car_yb , alien_xl,alien_xr,alien_yt,alien_yb )
    begin
        if rising_edge(clk) then
            -- top collision
            if (alien_xr >= car_xl) and (alien_xl <= car_xr) and ( (alien_yb <= car_yt) and (alien_yt >= car_yt) ) then
                gameover <= 1;
                --if ( gameover = 1) then gameover<=0; else gameover<=1; end if;
            -- bottom collision
            elsif (alien_xr >= car_xl) and (alien_xl <= car_xr) and ( (alien_yb <= car_yb) and (alien_yt >= car_yb) ) then
                gameover <= 1;
                --if ( gameover = 1) then gameover<=0; else gameover<=1; end if;
            -- left collision
            elsif (alien_yt <= car_yb) and (alien_yb >= car_yt) and ( (alien_xl <= car_xl) and (alien_xr >= car_xl) ) then
                gameover <= 1;
                --if ( gameover = 1) then gameover<=0; else gameover<=1; end if;
            -- right collision
            elsif (alien_yt <= car_yb) and (alien_yb >= car_yt) and ( (alien_xr >= car_xr) and (alien_xl <= car_xr) ) then
                gameover <= 1;
                --if ( gameover = 1) then gameover<=0; else gameover<=1; end if;
            end if;
        end if;
    end process;
    
    
    
    
    -- DRAW STUFF
    -- process to generate next colors           
    process (pixel_x, pixel_y)
    begin

           -- DRAW SPACESHIP
           if (unsigned(pixel_x) > car_xl) and (unsigned(pixel_x) < car_xr) and
           (unsigned(pixel_y) > car_yt) and (unsigned(pixel_y) < car_yb) then
               red_next <= "0000";
               green_next <= "1111";
               blue_next <= "1111"; 
               
           -- DRAW ALIEN
           elsif (unsigned(pixel_x) > alien_xl) and (unsigned(pixel_x) < alien_xr) and
           (unsigned(pixel_y) > alien_yt) and (unsigned(pixel_y) < alien_yb) then
               red_next <= "1111";
               green_next <= "0000";
               blue_next <= "0000";
               
           -- DRAW ALIEN 3
           elsif (unsigned(pixel_x) > alien3_xl) and (unsigned(pixel_x) < alien3_xr) and
           (unsigned(pixel_y) > alien3_yt) and (unsigned(pixel_y) < alien3_yb) and (gameover=0) then
               red_next <= "0000";
               green_next <= "1111";
               blue_next <= "0000";
           elsif (unsigned(pixel_x) > alien3_xl) and (unsigned(pixel_x) < alien3_xr) and
           (unsigned(pixel_y) > alien3_yt) and (unsigned(pixel_y) < alien3_yb) and (gameover=1) then
               red_next <= "1111";
               green_next <= "1111";
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