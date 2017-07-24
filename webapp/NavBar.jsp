    <div class="navbar">
      <div class="navbar-inner">
         <div class="container">
            <a class="btn btn-navbar" data-toggle="collapse" data-target=".navbar-responsive-collapse">
               <span class="icon-bar"></span>
               <span class="icon-bar"></span>
               <span class="icon-bar"></span>
            </a>
            <a class="brand" href="list.jsp"><b>Post Hoc</b> - {{mode}}</a>
           <div class="nav-collapse navbar-responsive-collapse">
              <ul class="nav">
                <li ><a href="list.jsp">Home</a></li>
                <li class="dropdown">
                  <a href="#" class="dropdown-toggle" data-toggle="dropdown">Options <b class="caret"></b></a>
                  <ul class="dropdown-menu">
                    <li><a href="main.jsp">Server Status</a></li>
                    <li class="divider"></li>
                    <li><a href="list.jsp">List All Mail</a></li>
                  </ul>
                </li>
              </ul>
              <ul class="nav pull-right">
                <li class="divider-vertical"></li>
                <li class="dropdown">
                  <a href="#" class="dropdown-toggle" data-toggle="dropdown">User <b class="caret"></b></a>
                  <ul class="dropdown-menu">
                    <li><a href="user.jsp">User Settings</a></li>
                    <li class="divider"></li>
                    <li><a href="user.jsp">Logout</a></li>
                  </ul>
                </li>
              </ul>
           </div><!-- /.nav-collapse -->
          </div> <!-- /.container -->
     </div><!-- /navbar-inner -->
   </div><!-- /navbar -->